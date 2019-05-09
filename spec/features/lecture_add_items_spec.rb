# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe "Adding a Lecture Item to the Schedule", type: :feature do
  before do
    @staff_user = create(:person, firstname: 'Staff', lastname: 'User',
                                  email: 'staff_user@staff.com')
    authenticate_user(@staff_user, :staff)
    @user.staff!

    @event = create(:event, start_date: Date.current + 1.month, time_zone: 'Auckland')
    @user.location = @event.location
    @user.save!
    create(:schedule, event: @event)

    @person = create(:person)
    @membership = create(:membership, person: @person, event: @event)
    @day = @event.start_date + 3.days
    @weekday = @day.strftime("%A")

    visit event_schedule_index_path(@event)
    click_link "Add an item on #{@weekday}"
  end

  after(:each) do
    Warden.test_reset!
  end

  it 'adds a Lecture' do
    page.fill_in 'schedule_name', with: 'New test lecture'
    page.fill_in 'schedule_location', with: 'Lecture room'
    select @person.lname, from: "schedule[lecture_attributes][person_id]"
    click_button 'Add New Schedule Item'

    expect(page).to have_content 'successfully scheduled'
    expect(Lecture.last.title == 'New test lecture').to be_truthy
  end

  it 'saves the lecture keywords, and removes trailing whitespace' do
    page.fill_in 'schedule_name', with: 'Testing lecture keywords'
    page.fill_in 'schedule_location', with: 'Lecture room'
    select @person.lname, from: "schedule[lecture_attributes][person_id]"
    page.fill_in 'schedule[lecture_attributes][keywords]',
                 with: ' RSpec, Testing, Hashtags '
    click_button 'Add New Schedule Item'

    new_lecture = Lecture.find_by_title('Testing lecture keywords')
    expect(new_lecture.keywords).to eq('RSpec, Testing, Hashtags')
  end

  it 'also adds a Schedule entry' do
    page.fill_in 'schedule_name', with: 'New Lecture'
    page.fill_in 'schedule_location', with: 'Lecture room'
    select @person.lname, from: "schedule[lecture_attributes][person_id]"
    click_button 'Add New Schedule Item'

    expect(page).to have_content 'successfully scheduled'
    expect(Schedule.last.name == "#{@person.name}: New Lecture").to be_truthy
  end

  it 'sets the lecture times in the associated event\'s time zone' do
    @event.time_zone = 'Sydney'
    @event.save
    visit event_schedule_index_path(@event)
    click_link "Add an item on #{@weekday}"

    page.fill_in 'schedule_name', with: 'New test lecture'
    page.fill_in 'schedule_location', with: 'Lecture room'
    select @person.lname, from: "schedule[lecture_attributes][person_id]"
    click_button 'Add New Schedule Item'
    expect(page).to have_content 'successfully scheduled'

    new_item = @event.lectures.first
    expect(new_item.start_time.time_zone.name).to eq(@event.time_zone)
    expect(new_item.end_time.time_zone.name).to eq(@event.time_zone)
  end

  it 'has a checkbox for indicating that recordings should not be published' do
    page.fill_in 'schedule_name', with: 'Testing Do Not Publish'
    page.fill_in 'schedule_location', with: 'Lecture room'
    select @person.lname, from: "schedule[lecture_attributes][person_id]"
    page.check('schedule[lecture_attributes][do_not_publish]')
    click_button 'Add New Schedule Item'

    lecture = Lecture.find_by_title('Testing Do Not Publish')
    expect(lecture.do_not_publish).to be_truthy
  end

  it 'sets do_not_publish to false if the checkbox is not checked' do
    page.fill_in 'schedule_name', with: 'Testing Do Not Publish 2'
    page.fill_in 'schedule_location', with: 'Lecture room'
    select @person.lname, from: "schedule[lecture_attributes][person_id]"
    click_button 'Add New Schedule Item'

    lecture = Lecture.find_by_title('Testing Do Not Publish 2')
    expect(lecture.do_not_publish).to be_falsey
  end

  it 'repopulates lecture description and title fields if validation fails' do
    page.fill_in 'schedule_name', with: 'Lecture 1'
    page.fill_in 'schedule_location', with: 'Lecture room'
    select @person.lname, from: 'schedule[lecture_attributes][person_id]'
    click_button 'Add New Schedule Item'

    lecture = Lecture.last
    start_hour = lecture.start_time.strftime('%H')
    start_min = lecture.start_time.strftime('%M')

    visit event_schedule_index_path(@event)
    click_link "Add an item on #{@weekday}"
    page.fill_in 'schedule_name', with: 'Lecture 2'
    page.fill_in 'schedule_location', with: 'Lecture room'
    page.fill_in 'schedule_description', with: 'Best talk ever!'
    select start_hour, from: 'schedule_start_time_4i'
    select start_min, from: 'schedule_start_time_5i'
    select @person.lname, from: 'schedule[lecture_attributes][person_id]'
    click_button 'Add New Schedule Item'

    expect(page).to have_content 'schedule could not be saved'
    expect(find_field('schedule_name').value).to eq('Lecture 2')
    expect(find_field('schedule_description').value).to eq('Best talk ever!')
  end

  it 'repopulates schedule description and title fields if validation fails' do
    page.fill_in 'schedule_name', with: 'Non-lecture'
    page.fill_in 'schedule_location', with: 'Lecture room'
    click_button 'Add New Schedule Item'

    schedule = Schedule.last
    start_hour = schedule.start_time.strftime('%H')
    start_min = schedule.start_time.strftime('%M')

    visit event_schedule_index_path(@event)
    click_link "Add an item on #{@weekday}"
    page.fill_in 'schedule_name', with: 'Lecture 2'
    page.fill_in 'schedule_location', with: ''
    page.fill_in 'schedule_description', with: 'Best talk ever!'
    select start_hour, from: 'schedule_start_time_4i'
    select start_min, from: 'schedule_start_time_5i'
    click_button 'Add New Schedule Item'

    expect(page).to have_content 'schedule could not be saved'
    expect(find_field('schedule_name').value).to eq('Lecture 2')
    expect(find_field('schedule_description').value).to eq('Best talk ever!')
  end
end
