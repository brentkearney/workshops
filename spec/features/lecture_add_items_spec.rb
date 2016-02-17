# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe "Adding a Lecture Item to the Schedule", :type => :feature do

  context 'As a Staff User' do
    before do
      @staff_user = FactoryGirl.create(:person, firstname: 'Staff', lastname: 'User', email: 'staff_user@320u4xs0aslsfjdf.com')
      authenticate_user(@staff_user, :staff)
      @user.staff!

      @event = FactoryGirl.create(:event, time_zone: 'Auckland')
      @user.location = @event.location
      @user.save!
      FactoryGirl.create(:schedule, event: @event)

      @person = FactoryGirl.create(:person)
      @membership = FactoryGirl.create(:membership, person: @person, event: @event)
      @day = @event.start_date + 3.days
      @weekday = @day.strftime("%A")

      visit event_schedule_index_path(@event)
    end

    after(:each) do
      Warden.test_reset!
    end

    it 'adds a Lecture' do
      click_link "Add an item on #{@weekday}"

      page.fill_in 'schedule_name', :with => 'New test lecture'
      page.fill_in 'schedule_location', :with => 'Lecture room'

      select @person.lname, :from => "schedule[lecture_attributes][person_id]"

      click_button 'Add New Schedule Item'

      expect(page).to have_content 'successfully scheduled'
      expect(@event.lectures.select {|s| s.title == 'New test lecture'}).not_to be_empty
    end

    it 'saves the lecture keywords' do
      click_link "Add an item on #{@weekday}"
      page.fill_in 'schedule_name', :with => 'Testing lecture keywords'
      page.fill_in 'schedule_location', :with => 'Lecture room'
      select @person.lname, :from => "schedule[lecture_attributes][person_id]"
      page.fill_in 'schedule[lecture_attributes][keywords]', :with => ' RSpec, Testing, Hashtags '
      click_button 'Add New Schedule Item'

      new_lecture = Lecture.find_by_title('Testing lecture keywords')
      expect(new_lecture.keywords).to eq('RSpec, Testing, Hashtags')
    end

    it 'also adds a Schedule entry' do
      click_link "Add an item on #{@weekday}"
      page.fill_in 'schedule_name', :with => 'New test lecture'
      page.fill_in 'schedule_location', :with => 'Lecture room'
      select @person.lname, :from => "schedule[lecture_attributes][person_id]"

      click_button 'Add New Schedule Item'

      expect(page).to have_content 'successfully scheduled'
      expect(@event.schedules.select {|s| s.name == "#{@person.name}: New test lecture"}).not_to be_empty
    end

    it 'sets the lecture times in the associated event\'s time zone' do
      @event.time_zone = 'Sydney'
      @event.save
      visit event_schedule_index_path(@event)

      click_link "Add an item on #{@weekday}"
      page.fill_in 'schedule_name', :with => 'New test lecture'
      page.fill_in 'schedule_location', :with => 'Lecture room'
      select @person.lname, :from => "schedule[lecture_attributes][person_id]"

      click_button 'Add New Schedule Item'

      expect(page).to have_content 'successfully scheduled'

      new_item = @event.lectures.first
      expect(new_item.start_time.time_zone.name).to eq(@event.time_zone)
      expect(new_item.end_time.time_zone.name).to eq(@event.time_zone)
    end

    it 'has a checkbox for indicating that recordings should not be published' do
      click_link "Add an item on #{@weekday}"
      page.fill_in 'schedule_name', :with => 'Testing Do Not Publish'
      page.fill_in 'schedule_location', :with => 'Lecture room'
      select @person.lname, :from => "schedule[lecture_attributes][person_id]"

      page.check('schedule[lecture_attributes][do_not_publish]')

      click_button 'Add New Schedule Item'
      lecture = Lecture.find_by_title('Testing Do Not Publish')
      expect(lecture.do_not_publish).to be_truthy
    end

    it 'sets do_not_publish to false if the checkbox is not checked' do
      click_link "Add an item on #{@weekday}"
      page.fill_in 'schedule_name', :with => 'Testing Do Not Publish 2'
      page.fill_in 'schedule_location', :with => 'Lecture room'
      select @person.lname, :from => "schedule[lecture_attributes][person_id]"

      click_button 'Add New Schedule Item'
      lecture = Lecture.find_by_title('Testing Do Not Publish 2')
      expect(lecture.do_not_publish).to be_falsey
    end
  end

  context 'As an Organizer' do
    before do
      @organizer = FactoryGirl.create(:person, firstname: 'Organizer', lastname: 'User', email: 'organizer@320u4xs0aslsfjdf.com')
      authenticate_user(@organizer, :member)

      @event = FactoryGirl.create(:event, time_zone: 'Hawaii')
      @person = FactoryGirl.create(:person)
      @membership = FactoryGirl.create(:membership, person: @person, event: @event)
      @day = @event.start_date + 3.days
      @weekday = @day.strftime("%A")

      visit event_schedule_index_path(@event)
    end

    after(:each) do
      Warden.test_reset!
    end
  end
end
