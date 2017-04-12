# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'RSVP', type: :feature do
  before do
    @invitation = create(:invitation)
    @membership = @invitation.membership
    @membership.attendance ='Invited'
    @membership.save
    @event = @membership.event
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
    it 'past events'
    it 'expired invitations'
    it 'non-existent invitations'
    it 'participant not invited'
    it 'participant already declined'
    it 'participant already confirmed'
  end

  context 'User says No' do
    before :each do
      @lc = FakeLegacyConnector.new
      allow(LegacyConnector).to receive(:new).and_return(@lc)

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
      membership = create(:membership, attendance: 'Invited')
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

      invite = create(:invitation, membership: @membership)
      visit rsvp_otp_path(invite.code)
      click_link 'No'

      expect(lc).to have_received(:update_member).with(@membership)
    end
  end

  context 'User says Maybe' do
    it 'says thanks'
    it 'displays invitation expiry date'
    it 'changes membership attendance to maybe'
    it 'notifies organizer'
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
  end
end
