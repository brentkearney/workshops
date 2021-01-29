# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Schedule Index', type: :feature do
  before do
    authenticate_user
    @event = create(:event, current: true)
    @template_event = build_schedule_template(@event.event_type)
  end

  after(:each) do
    Warden.test_reset!
  end

  def populates_empty_schedule
    @event.schedules.destroy_all
    visit(event_schedule_index_path(@event))

    @event.reload
    expect(@event.schedules).not_to be_empty
    @template_event.schedules.each do |item|
      expect(page.body).to have_text(item.name)
    end
  end

  def does_not_populate_empty_schedule
    @event.schedules.destroy_all
    visit(event_schedule_index_path(@event))

    expect(@event.schedules).to be_empty
  end

  def reloads_template_schedule
    @event.schedules.destroy_all

    visit(event_schedule_index_path(@event))
    @template_event.schedules.each do |item|
      expect(page.body).to have_text(item.name)
    end

    template_item = @template_event.schedules.third
    template_item.name = 'Altered item'
    template_item.save

    visit(event_schedule_index_path(@event))
    expect(page.body).to have_text('Altered item')
    expect(@event.schedules.count).to eq(@template_event.schedules.count)
  end

  context 'Admin users' do
    before do
      @user.admin!
    end

    it 'populates an empty schedule from the template event schedule' do
      populates_empty_schedule
    end

    it 'reloads the template schedule if no schedule changes have been made' do
      reloads_template_schedule
    end
  end

  context 'Organizers of event' do
    before do
      @user.member!
      create(:membership, event: @event,
                          person: @user.person,
                          role: 'Organizer')
    end

    it 'populates an empty schedule from the template event schedule' do
      populates_empty_schedule
    end

    it 'reloads the template schedule if no schedule changes have been made' do
      reloads_template_schedule
    end

    it 'has delete buttons on schedule items' do
      @event.schedules.destroy_all

      visit(event_schedule_index_path(@event))
      @event.reload
      expect(@event.schedules).not_to be_empty

      @event.schedules.each do |item|
        item_path = "/events/#{@event.code}/schedule/#{item.id}"
        delete_link = page.find(:xpath, "//a[@href='#{item_path}'
          and @data-method='delete']")
        expect(delete_link).not_to be_nil
      end
    end

    it 'has no delete buttons on staff items when current time is within lock
      period' do
      lc = @event.location
      lead_time = Setting.Locations[lc]['lock_staff_schedule'].to_duration
      @event.start_date = Date.current + lead_time - 3.days
      @event.end_date = @event.start_date + 5.days
      @event.save

      @event.schedules.destroy_all

      visit(event_schedule_index_path(@event))
      @event.reload
      expect(@event.schedules).not_to be_empty

      @event.schedules.each do |item|
        item_path = "/events/#{@event.code}/schedule/#{item.id}"
        expect(page).to have_no_selector(:xpath, "//a[@href='#{item_path}'
          and @data-method='delete']")
      end
    end

    context "Start/Stop Recording buttons" do
      before do
        # has to be today because buttons only appear today
        date = Date.today
        @event.start_date = date.beginning_of_week(:sunday)
        @event.end_date = @event.start_date + 2.weeks # in case today is Friday
        @event.save
        @event.schedules.destroy_all
        build_lecture_schedule(@event)

        @lecture = create(:lecture, event: @event,
                               start_time: DateTime.current + 20.minutes,
                                 end_time: DateTime.current + 40.minutes,
                                    title: 'The Talk',
                                     room: 'Online')
        @schedule_item = create(:schedule, lecture: @lecture,
                                             event: @event,
                                        start_time: @lecture.start_time,
                                          end_time: @lecture.end_time,
                                              name: @lecture.title,
                                          location: @lecture.room)

        @link = "/events/#{@event.code}/schedule/#{@schedule_item.id}/recording"
      end

      it "has Start Recording buttons for today's future lectures" do
        visit(event_schedule_index_path(@event))

        expect(page).to have_link('Start Recording', href: "#{@link}/start")
      end

      it "clicking Start Recording updates is_recording, notifies" do
        expect(@lecture.is_recording).to be_falsey
        visit(event_schedule_index_path(@event))

        find_link('Start Recording', href: "#{@link}/start").click

        expect(Lecture.find(@lecture.id).is_recording).to be_truthy
        expect(page.find('div', class: 'alert-success', text: /Starting recording for/))
      end

      it "hides Start Recording buttons when a lecture is recording" do
        @lecture.is_recording = true
        @lecture.save

        visit(event_schedule_index_path(@event))

        expect(page).not_to have_link('Start Recording', href: "#{@link}/start")
      end

      it "hides Start Recording buttons after Stop Recording is pressed" do
        @lecture.is_recording = true
        @lecture.save

        visit(event_schedule_index_path(@event))
        find_link('Stop Recording', href: "#{@link}/stop").click

        expect(current_path).to eq(event_schedule_index_path(@event))
        expect(page).not_to have_link('Start Recording', href: "#{@link}/start")
        expect(Lecture.find(@lecture.id).filename).to eq('pending')
      end

      it "has a Stop Recording button for the lecture that is recording" do
        @lecture.is_recording = true
        @lecture.save

        visit(event_schedule_index_path(@event))

        expect(page).to have_link('Stop Recording', href: "#{@link}/stop")
      end

      it "if recording is already started, and start is pressed again,
            does nothing and warns" do
        visit(event_schedule_index_path(@event))

        @lecture.is_recording = true
        @lecture.save
        updated_at = Lecture.find(@lecture.id).updated_at

        find_link('Start Recording', href: "#{@link}/start").click

        expect(Lecture.find(@lecture.id).updated_at).to eq(updated_at)
        expect(page.find('div', class: 'alert-error',
                                 text: /Already recording/))
      end

      it "if a different lecture is already recording, flash message says so" do
        visit(event_schedule_index_path(@event))

        other_lecture = create(:lecture, event: @event,
                               start_time: @lecture.start_time + 60.minutes,
                                 end_time: @lecture.end_time + 80.minutes,
                                    title: 'Another Talk',
                             is_recording: true,
                                     room: 'Online')

        find_link('Start Recording', href: "#{@link}/start").click

        expect(Lecture.find(@lecture.id).is_recording).to be_falsey

        error_message = %Q{Already recording "#{other_lecture.person.name}:
                  #{other_lecture.title}".}.squish
        expect(page.find('div', class: 'alert-error',
                                 text: error_message))
      end

      it 'clicking Stop Recording updates is_recording, notifies' do
        @lecture.is_recording = true
        @lecture.save

        visit(event_schedule_index_path(@event))
        find_link('Stop Recording', href: "#{@link}/stop").click

        expect(Lecture.find(@lecture.id).is_recording).to be_falsey
        expect(page.find('div', class: 'alert-notice',
                                 text: 'Recording stopped.'))
      end
    end
  end

  context 'Organizers of other event' do
    before do
      Membership.destroy_all
      new_event = create(:event)
      create(:membership, event: new_event,
                          person: @user.person,
                          role: 'Organizer')
    end

    it 'does not populates an empty schedule from the template' do
      does_not_populate_empty_schedule
    end
  end

  context 'Participants' do
    before do
      membership = create(:membership, role: 'Participant')
      authenticate_user(membership.person, 'member')
    end

    it 'does not populates an empty schedule from the template' do
      does_not_populate_empty_schedule
    end
  end
end
