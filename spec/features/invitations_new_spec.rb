# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Invitation#new', type: :feature do
  before do
    create(:event, past: true)
    @current_event = create(:event, current: true)
    3.times { create(:event, future: true) }
  end

  before :each do
    visit invitations_new_path
  end

  def expect_email_sent
    expect(page.body).to have_css('div.alert',
        text: 'A new invitation has been sent!')
  end

  it 'has a SELECT menu of future events' do
    future_events = Event.future.map(&:code) - [@current_event.code]
    past_events = Event.past.map(&:code)

    expect(page.body).to have_select('invitation[event]', with_options: future_events)
    expect(page.body).not_to have_select('invitation[event]', with_options: past_events)
  end

  it 'preselects event if it was passed into the URI' do
    event = Event.future.last
    visit "#{invitations_new_path}/#{event.code}"
    expect( find(:css, 'select#invitation_event').value ).to eq(event.code)

    visit "#{invitations_new_path}/#{event.id}"
    expect( find(:css, 'select#invitation_event').value ).to eq(event.code)
  end

  it 'excludes events for whose expiry dates will already have passed' do
    expect(page.body).not_to have_select('invitation[event]', with_options: [@current_event.code])
  end

  it 'has an email field' do
    expect(page.body).to have_field('invitation[email]')
  end

  context 'validates email' do
    before :each do
      find('#invitation_event').find(:xpath, 'option[2]').select_option
    end

    it 'no email' do
      click_button 'Request Invitation'
      expect(page.body).to have_css('div.alert',
          text: 'Your e-mail address is required')
    end

    it 'invalid email' do
      page.fill_in 'invitation[email]', with: 'foo@bar'
      click_button 'Request Invitation'

      expect(page.body).to have_css('div.alert',
          text: 'You must enter a valid e-mail address')
    end

    it 'valid email' do
      event = Event.last
      member = create(:membership, event: event, attendance: 'Invited')

      select "#{event.name}", from: 'invitation_event'
      page.fill_in 'invitation[email]', with: member.person.email
      click_button 'Request Invitation'

      expect_email_sent
    end
  end

  context 'validates event' do
    it 'no event selected' do
      page.fill_in 'invitation[email]', with: 'foo@bar'
      click_button 'Request Invitation'

      expect(page.body).to have_css('div.alert',
          text: 'You must select the event to which you were invited')
    end
  end

  context 'validates membership' do
    before do
      @event = Event.last
      @member = create(:membership, event: @event)
    end

    def submit_member_request(member)
      select "#{@event.name}", from: 'invitation_event'
      page.fill_in 'invitation[email]', with: member.person.email
      click_button 'Request Invitation'
    end

    it 'no membership' do
      find('#invitation_event').find(:xpath, 'option[2]').select_option
      page.fill_in 'invitation[email]', with: 'foo@bar.com'
      click_button 'Request Invitation'

      expect(page.body).to have_css('div.alert',
          text: 'We have no record of that email address')
    end

    it 'already confirmed' do
      @member.attendance = 'Confirmed'
      @member.save

      submit_member_request(@member)

      expect_email_sent
    end

    it 'already declined' do
      @member.attendance = 'Declined'
      @member.save!

      submit_member_request(@member)

      expect(page.body).to have_css('div.alert',
          text: 'You have already declined an invitation')
    end

    it 'not yet invited' do
      @member.attendance = 'Not Yet Invited'
      @member.save

      submit_member_request(@member)

      expect(page.body).to have_css('div.alert',
        text: "The event's organizers have not yet\n              invited you")
    end

    it 'invited' do
      @member.attendance = 'Invited'
      @member.save

      submit_member_request(@member)

      expect_email_sent
    end

    it 'undecided' do
      @member.attendance = 'Undecided'
      @member.save

      submit_member_request(@member)

      expect_email_sent
    end
  end
end
