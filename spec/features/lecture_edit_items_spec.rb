# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Editing a Lecture Item', :type => :feature do
  before do
    authenticate_user

    @event = FactoryGirl.create(:event)

    9.upto(12) do |t|
      FactoryGirl.create(:schedule,
                         event: @event,
                         name: "Item at #{t}:00",
                         start_time: (@event.start_date + 2.days).to_time.change({ hour: t }),
                         end_time: (@event.start_date + 2.days).to_time.change({ hour: t+1 })
      )
    end

    @event.schedules.each do |s|
      person = FactoryGirl.create(:person)
      FactoryGirl.create(:membership, event: @event, person: person)
      lecture = FactoryGirl.create(:lecture, event: @event, person: person, start_time: s.start_time, end_time: s.end_time)
      s.lecture = lecture
      s.save
    end
    @item = @event.schedules.first
    @lecture = @item.lecture
    visit event_schedule_edit_path(@event, @item)
  end

  after(:each) do
    Warden.test_reset!
  end

  it 'updates the day of the item to the selected day' do
    new_day = @item.start_time.to_date + 1.day
    page.select new_day.strftime("%A"), :from => 'schedule_day'
    click_button 'Update Schedule'
    expect(Lecture.find(@lecture.id).start_time.to_date).to eq(new_day)
  end

  it 'updates the keywords, stripping whitespace' do
    expect(@lecture.keywords).to be_nil
    page.fill_in 'schedule[lecture_attributes][keywords]', :with => ' RSpec, Testing, Hashtags '
    click_button 'Update Schedule'
    expect(Lecture.find(@lecture.id).keywords).to eq('RSpec, Testing, Hashtags')
  end

  it 'updates the times of the lecture to the selected times' do
    new_start = @item.start_time + 6.hours
    new_end = new_start + 1.hours
    page.select new_start.strftime("%H"), :from => 'schedule_start_time_4i'
    page.select new_end.strftime("%H"), :from => 'schedule_end_time_4i'
    click_button 'Update Schedule'
    expect(Lecture.find(@lecture.id).start_time).to eq(new_start)
    expect(Lecture.find(@lecture.id).end_time).to eq(new_end)
  end

  it 'updates the title of the lecture item' do
    page.fill_in 'schedule_name', :with => 'Better name than nth item'
    click_button 'Update Schedule'
    expect(Lecture.find(@lecture.id).title).to eq('Better name than nth item')
  end

  it 'changes the associated person if a new one is selected' do
    other_lecture = @event.lectures.first
    new_person = other_lecture.person
    page.select new_person.lname, :from => 'schedule[lecture_attributes][person_id]'
    click_button 'Update Schedule'

    #expect(page.body).to include("\"#{new_person.name}: #{@lecture.title}\" was successfully updated.")
    expect(Lecture.find(other_lecture.id).person_id).to eq(new_person.id)
    expect(Schedule.find(@item.id).name).to eq("#{new_person.name}: #{@lecture.title}")
  end

  it 'updates the name of the schedule item to include the Lecture\'s name' do
    page.fill_in 'schedule_name', :with => 'Better name than nth item'
    click_button 'Update Schedule'
    expect(Schedule.find(@item.id).name).to eq("#{@lecture.person.name}: Better name than nth item")
  end

  it 'updates the abstract of the lecture item' do
    page.fill_in 'schedule_description', :with => 'Here is a new abstract.'
    click_button 'Update Schedule'
    expect(Lecture.find(@lecture.id).abstract).to eq('Here is a new abstract.')
  end

  it 'updates the room of the lecture item' do
    page.fill_in 'schedule_location', :with => 'In the woods'
    click_button 'Update Schedule'
    expect(Lecture.find(@lecture.id).room).to eq('In the woods')
  end

  it 'changes the do_not_publish field from false to true' do
    page.check('schedule[lecture_attributes][do_not_publish]')
    click_button 'Update Schedule'
    expect(Lecture.find(@lecture.id).do_not_publish).to be_truthy
  end

  it 'changes the do_not_publish field from false to true' do
    @lecture.do_not_publish = true
    @lecture.save!
    visit event_schedule_edit_path(@event, @item)

    page.uncheck('schedule[lecture_attributes][do_not_publish]')
    click_button 'Update Schedule'
    expect(Lecture.find(@lecture.id).do_not_publish).to be_falsey
  end

end