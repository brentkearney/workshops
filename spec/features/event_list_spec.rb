# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Event List', type: :feature do
  before do
    @past = create(:event, past: true)
    @current = create(:event, current: true)
    @future = create(:event, future: true)
    authenticate_user # creates @person, @user
  end

  after do
    Event.destroy_all
    Person.destroy_all
  end

  describe 'Navigation Links' do
    it '#My Events' do
      visit root_path
      expect(page.body).to have_link('My Events')
    end

    it '#All Events' do
      visit root_path
      expect(page.body).to have_link('All Events')
    end

    it '#Future Events' do
      visit root_path
      expect(page.body).to have_link('Future Events')
    end

    it '#Past Events' do
      visit root_path
      expect(page.body).to have_link('Past Events')
    end

    describe '#Event Years' do
      it 'has a link' do
        visit root_path
        expect(page.body).to have_link('Event Years')
      end

      it 'the link expands to show event years' do
        visit root_path
        years = page.all('ul#event-years-list a').map(&:text)

        expect(years).to include(@past.year)
        expect(years).to include(@current.year)
        expect(years).to include(@future.year)
      end
    end

    describe '#Event Locations' do
      it 'has a link' do
        visit root_path
        expect(page.body).to have_link('Event Locations')
      end

      it 'expands to show event locations' do
        visit root_path
        locations =
          page.all('ul#event-locations-list a').map(&:text)

        expect(locations).to include(@past.location)
        expect(locations).to include(@current.location)
        expect(locations).to include(@future.location)
      end
    end
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

    it 'orders by date' do
      visit events_path
      expect(page.body.index(@past.code) < page.body.index(@current.code))
      expect(page.body.index(@current.code) < page.body.index(@future.code))
    end

    it 'indicates which country each event is in' do
      visit events_path
      expect(page.body).to include("flags/#{@past.country}")
      expect(page.body).to include("flags/#{@current.country}")
      expect(page.body).to include("flags/#{@future.country}")
    end

    it 'shows the number of confirmed participants' do
      3.times do
        create(:membership, event: @current)
      end

      visit events_path
      confirmed_counts = page.all('table#events-list td.confirmed').map(&:text)

      expect(confirmed_counts).to eq(['0', '3', '0'])
    end

  end

  describe 'My Events' do
    it 'lists the current user\'s events' do
      person = create(:person)
      member_user = create(:user, person: person)
      create(:membership, person: person, event: @future,
        attendance: 'Confirmed')

      logout(@user)
      login_as member_user, scope: :user
      visit my_events_path

      expect(page.body).to have_text(@future.code)
      expect(page.body).not_to have_text(@past.code)
      expect(page.body).not_to have_text(@current.code)

      logout(member_user)
      authenticate_user
    end
  end

  describe 'Future Events' do
    it 'lists events in the future'
  end

  describe 'Past Events' do
    it 'lists events in the past'
  end

  describe 'Event Years' do
    it 'lists events for selected year'
    it 'allows toggle by location'
  end

  describe 'Event Locations' do
    it 'shows a link for each location of events'
    it 'lists events for selected location'
    it 'allows toggle by year'
  end
end
