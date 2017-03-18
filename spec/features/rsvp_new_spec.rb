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

  it 'has a drop-down list of future events' do
    future_events = Event.future.map(&:code)
    expect(page.body).to have_select('event', with_options: future_events)
  end
end
