# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Event List', type: :feature do
  before do
    @past = create(:event_with_members, past: true)
    @current = create(:event_with_members, current: true)
    @future = create(:event_with_members, future: true)
    authenticate_user
  end

  after do
    Event.destroy_all
  end

  describe 'All Events' do
    it 'lists all events\' code, name, date' do
      events = Event.all
      visit events_path

      events.each do |event|
        expect(page.body).to have_text(event.code)
        expect(page.body).to have_text(event.name)
        expect(page.body).to have_text(event.dates)
      end
    end

    it 'orders by date'
    it 'indicates which country the event is in'
    it 'shows the number of confirmed participants'
  end

  describe 'My Events' do
    it 'lists the current user\'s events'
  end

  describe 'Future Events' do
    it 'lists events in the future'
  end

  describe 'Past Events' do
    it 'lists events in the past'
  end

  describe 'Events by Year' do
    it 'shows a link for each year of events'
    it 'lists events for selected year'
    it 'allows toggle by location'
  end

  describe 'Event Locations' do
    it 'shows a link for each location of events'
    it 'lists events for selected location'
    it 'allows toggle by year'
  end
end
