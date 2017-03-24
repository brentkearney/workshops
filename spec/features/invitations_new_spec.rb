# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Invitation#new', type: :feature do
  before do
    create(:event, past: true)
    3.times { create(:event, future: true) }
  end

  before :each do
    visit invitations_new_path
  end

  it 'has a SELECT menu of future events' do
    future_events = Event.future.map(&:code)
    past_events = Event.past.map(&:code)

    expect(page.body).to have_select('invitation[event]', with_options: future_events)
    expect(page.body).not_to have_select('invitation[event]', with_options: past_events)
  end

  it 'has an email field' do
    expect(page.body).to have_field('invitation[email]')
  end

  context 'validates email' do
    it 'no email'
    it 'invalid email' do
      find('#invitation_event').find(:xpath, 'option[2]').select_option
      page.fill_in 'invitation[email]', with: 'foo@bar'
      click_button 'Request Invitation'

      expect(page.body).to have_css('div.alert',
          text: 'You must enter a valid e-mail address')
    end
    it 'valid email'
  end

  context 'validates event' do
    it 'no event'
    it 'invalid event'
    it 'valid event'
  end

  context 'validates membership' do
    it 'no membership'
    it 'not invited'
    it 'already confirmed'
    it 'already declined'
    it 'not yet invited'
    it 'invited'
    it 'undecided'
  end
end
