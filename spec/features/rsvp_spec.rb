# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'RSVP', type: :feature do
  before do
    @lc = FakeLegacyConnector.new
    allow(LegacyConnector).to receive(:new).and_return(@lc)

    @event = create(:event, future: true)
    @membership = create(:membership, event: @event)
    @membership.attendance ='Invited'
    @membership.save
    @invitation = create(:invitation, membership: @membership)
    @person = @membership.person
  end

  before :each do
    visit rsvp_otp_path(@invitation.code)
  end

  it 'welcomes the user' do
    expect(current_path).to eq(rsvp_otp_path(@invitation.code))
    expect(page.body).to have_text("Dear #{@person.dear_name}:")
  end

  it 'displays the event name and date' do
    expect(page.body).to have_text(@event.name)
    expect(page.body).to have_text(@event.dates('long'))
  end

  it 'has yes, no, maybe buttons' do
    expect(page).to have_link('Yes')
    expect(page).to have_link('No')
    expect(page).to have_link('Maybe')
  end

  context 'Error conditions' do
    it 'past events' do
      @event.start_date = Date.today.last_year
      @event.end_date = Date.today.last_year + 5.days
      @event.save!

      visit rsvp_otp_path(@invitation.code)

      expect(page).to have_text('You cannot RSVP for past events')
    end

    it 'expired invitations' do
      @invitation.expires = Date.today.last_year
      @invitation.save

      visit rsvp_otp_path(@invitation.code)

      expect(page).to have_text('This invitation code is expired')
      @invitation.expires = Date.today.next_year
      @invitation.save
    end

    it 'non-existent invitations' do
      response = {'denied' => 'Invalid code'}
      lc = FakeLegacyConnector.new
      expect(LegacyConnector).to receive('new').and_return(lc)
      allow(lc).to receive('check_rsvp').and_return(response)

      visit rsvp_otp_path(123)

      expect(page).to have_text('Invalid code')
    end

    it 'participant not invited' do
      @membership.attendance = 'Not Yet Invited'
      @membership.save

      visit rsvp_otp_path(@invitation.code)

      expect(page).to have_text("The event's organizers have not yet
        invited you")
    end

    it 'participant already declined' do
      @membership.attendance = 'Declined'
      @membership.save

      visit rsvp_otp_path(@invitation.code)

      expect(page).to have_text("You have already declined an invitation")
    end
  end

  context 'User says No' do
    before :each do
      click_link 'No'
    end

    it 'says thanks' do
      expect(page).to have_text('Thank you')
    end

    it 'declines membership' do
      expect(Membership.find(@membership.id).attendance).to eq('Declined')
    end

    it 'destroys invitation' do
      expect(Invitation.where(id: @invitation.id)).to be_empty
    end

    it 'notifies the event organizer' do
      ActionMailer::Base.deliveries = []
      event = create(:event, future: true)
      membership = create(:membership, attendance: 'Invited', event: event)
      organizer = create(:membership, role: 'Contact Organizer',
                                     event: membership.event).person
      invite = create(:invitation, membership: membership)

      expect(membership.attendance).to eq('Invited')
      visit rsvp_otp_path(invite.code)
      click_link 'No'

      expect(ActionMailer::Base.deliveries.count).not_to be_zero
      expect(ActionMailer::Base.deliveries.first.to).to include(organizer.email)
    end

    it 'updates legacy database' do
      lc = spy('lc')
      allow(LegacyConnector).to receive(:new).and_return(lc)

      event = create(:event, future: true)
      membership = create(:membership, attendance: 'Invited', event: event)
      invite = create(:invitation, membership: membership)
      visit rsvp_otp_path(invite.code)
      click_link 'No'

      expect(lc).to have_received(:update_member).with(membership)
    end
  end

  context 'User says Maybe' do
    it 'says thanks'
    it 'displays invitation expiry date'
    it 'changes membership attendance to maybe'
    it 'notifies organizer'
    it 'updates legacy database'
  end

  context 'User says Yes' do
    it 'displays profile form'
    it 'displays date selection'
    it 'displays guest and food form'
    it 'displays messages form'
    it 'says thanks'
    it 'links to relevant info'
    it 'changes membership attendance to confirmed'
    it 'destroys invitation'
    it 'notifies organizer'
    it 'updates legacy database'
  end
end
