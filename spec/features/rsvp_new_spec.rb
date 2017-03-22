# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'RSVP#new', type: :feature do
  before do
    create(:event, past: true)
    3.times { create(:event, future: true) }
  end

  before :each do
    visit rsvp_new_path
  end

  it 'has a SELECT menu of future events' do
    future_events = Event.future.map(&:code)
    past_events = Event.past.map(&:code)

    expect(page.body).to have_select('event', with_options: future_events)
    expect(page.body).not_to have_select('event', with_options: past_events)
  end

  it 'has an email field' do
    expect(page.body).to have_field('person_email')
  end

  it 'validates email' do
    option = first('#event option').text
    puts "Selecting option: #{option}"
    select option, from: 'event'

    page.fill_in 'person_email', with: 'foo@bar'
    click_button 'Request Another Invitation'

    expect(current_path).to eq(rsvp_new_path)
    expect(page.body).to have_css('div.alert-error',
        text: 'Invalid email address')
  end
end
