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

      it 'expands to show event years' do
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
    it 'lists current event + events in the future' do
      visit root_path

      click_link 'Future Events'

      expect(page.body).to have_text(@current.name)
      expect(page.body).not_to have_text(@past.name)
      expect(page.body).to have_text(@future.name)
    end
  end

  describe 'Past Events' do
    it 'lists events in the past' do
      visit root_path

      click_link 'Past Events'

      expect(page.body).not_to have_text(@current.name)
      expect(page.body).to have_text(@past.name)
      expect(page.body).not_to have_text(@future.name)
    end
  end

  describe 'Event Years' do
    it 'lists events for selected year' do
      year = @past.year

      visit root_path
      click_link 'Event Years'
      click_link "#{year}"

      expect(current_path).to eq(events_year_path(year))
      expect(page.body).to have_text(@past.name)
    end

    it 'location view can toggle by year' do
      location = @past.location
      @future.location = location
      @future.save

      visit events_location_path(location)

      click_link 'Event Years'
      click_link @past.year

      expect(page.body).not_to have_text(@future.name)
    end

  end

  describe 'Event Locations' do
    it 'lists events for selected location' do
      location = @current.location

      visit root_path
      click_link 'Event Locations'
      click_link "#{location}"

      expect(current_path).to eq(events_location_path(location))
      expect(page.body).to have_text(@current.name)
    end

    it 'past events view can toggle by location' do
      start_date = @past.start_date.advance(weeks: 1)
      end_date = start_date.advance(days: 5)
      past2 = create(:event, start_date: start_date, 
        end_date: end_date, location: 'XOXO')

      visit events_past_path
      click_link 'Event Locations'
      click_link @past.location

      expect(page.body).to have_text(@past.name)
      expect(page.body).not_to have_text(past2.name)
      expect(page.body).not_to have_text(@future.name)
    end

    it 'year view can toggle by location' do
      event1 = create(:event)
      event2 = create(:event, location: 'XOXO')
      
      visit events_year_path(event1.year)
      expect(page.body).to have_text(event1.name)
      expect(page.body).to have_text(event2.name)

      click_link 'Event Years'
      click_link event1.location

      expect(page.body).not_to have_text(event2.name)
    end
  end
end
