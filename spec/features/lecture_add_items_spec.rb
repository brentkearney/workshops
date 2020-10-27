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

  def add_a_lecture(title:, location:)
    page.fill_in 'schedule_name', with: "#{title}"
    page.fill_in 'schedule_location', with: "#{location}"
    select @person.lname, from: "schedule[lecture_attributes][person_id]"
    click_button 'Add New Schedule Item'
  end

  it 'adds a Lecture' do
    add_a_lecture(title: "New test lecture", location: "Room 1")

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

  it 'disallows overlapping lectures in the same location, same event' do
    add_a_lecture(title: "Test lecture 1", location: "Room 1")
    lecture = Lecture.last
    expect(lecture.title == 'Test lecture 1').to be_truthy

    new_member = create(:membership, event: @event)

    visit event_schedule_index_path(@event)
    click_link "Add an item on #{@weekday}"

    new_start = lecture.start_time - 5.minutes
    new_stop = lecture.start_time + 5.minutes

    page.fill_in 'schedule_name', with: "Test lecture 2"
    page.select new_start.strftime('%H'), from: 'schedule_start_time_4i'
    page.select new_start.strftime('%M'), from: 'schedule_start_time_5i'
    page.select new_stop.strftime('%H'), from: 'schedule_end_time_4i'
    page.select new_stop.strftime('%M'), from: 'schedule_end_time_5i'
    page.fill_in 'schedule_location', with: 'Room 1'
    select new_member.person.lname,
        from: "schedule[lecture_attributes][person_id]"

    click_button 'Add New Schedule Item'

    expect(Lecture.last.title).not_to eq("Test lecture 2")
    error_string = "Lecture time cannot overlap with another lecture "
    error_string << "at the same location: #{@person.name} at Room 1 during "
    error_string << "#{lecture.start_time.strftime('%H:%M')} - "
    error_string << "#{lecture.end_time.strftime('%H:%M')}"
    expect(find('div.alert-danger').text)
      .to include("#{error_string}")
  end

  it 'disallows overlapping lectures in the same location, different event' do
    add_a_lecture(title: "Test lecture 1", location: "Room 1")
    lecture = Lecture.last

    new_event = create(:event, start_date: @event.start_date,
                                 end_date: @event.end_date)
    new_member = create(:membership, event: new_event)
    visit event_schedule_index_path(new_event)
    click_link "Add an item on #{lecture.start_time.strftime("%A")}"

    new_start = lecture.start_time - 5.minutes
    new_stop = lecture.start_time + 10.minutes

    page.fill_in 'schedule_name', with: "Test lecture 2"
    page.select new_start.strftime('%H'), from: 'schedule_start_time_4i'
    page.select new_start.strftime('%M'), from: 'schedule_start_time_5i'
    page.select new_stop.strftime('%H'), from: 'schedule_end_time_4i'
    page.select new_stop.strftime('%M'), from: 'schedule_end_time_5i'
    page.fill_in 'schedule_location', with: 'Room 1'
    select new_member.person.lname,
        from: "schedule[lecture_attributes][person_id]"

    click_button 'Add New Schedule Item'

    expect(page.body).not_to have_content 'successfully scheduled'
    expect(Lecture.last.title).not_to eq("Test lecture 2")
    error_string = "Lecture time cannot overlap with another lecture "
    error_string << "at the same location: #{@person.name} at Room 1 during "
    error_string << "#{lecture.start_time.strftime('%H:%M')} - "
    error_string << "#{lecture.end_time.strftime('%H:%M')}"
    expect(find('div.alert-danger').text).to include("#{error_string}")

    other_schedule = "See the #{@event.code} schedule for details."
    expect(find('div.alert-danger').text).to include("#{other_schedule}")
  end
end
