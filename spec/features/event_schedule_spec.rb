# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Event Schedule Page', :type => :feature do
  before do
    authenticate_user

    @event = FactoryGirl.create(:event)
    9.upto(12) do |t|
      FactoryGirl.create(:schedule,
                         event: @event,
                         name: "Item at #{t}",
                         start_time: (@event.start_date + 2.days).to_time.change({ hour: t }),
                         end_time: (@event.start_date + 2.days).to_time.change({ hour: t+1 })
      )
    end

    visit event_schedule_index_path(@event)
  end

  after(:each) do
    Warden.test_reset!
  end

  it 'has headings for each day of the workshop' do
    @event.days.each do |day|
      expect(page.body).to have_css('div', text: "#{day.strftime("%A, %b %e")}")
    end
  end

  it 'lists each days scheduled items, with a link to edit it' do
    @event.schedules.each do |item|
      expect(page.body).to have_link(item.name, href: event_schedule_edit_path(@event, item))
    end
  end

  it 'if the event.location is not BIRS, includes a button to Send Video Filenames' do
    @event.location = 'CMO'
    @event.save
    visit event_schedule_index_path(@event)
    expect(page.body).to have_link("Send Video Filenames to #{@event.location}")
  end

end
