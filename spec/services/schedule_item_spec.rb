# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe "ScheduleItem" do
  before do
    @user = authenticate_user
    @event = create(:event)
    @person = create(:person)
    @schedule_attributes = {
          event_id: @event.id,
        start_time: second_day_at_nine,
          end_time: (second_day_at_nine + 1.hour),
              name: 'Good morning!',
       description: 'The first item of the day.',
          location: 'TCPL 201',
        updated_by: "RSpec"
    }
    @new_params = {
          new_item: true,
          event_id: @event.id,
        start_time: @event.start_date.to_time,
        updated_by: @user.name
    }
  end

  after(:each) do
    Warden.test_reset!
  end

  after do
    Lecture.delete_all
    Schedule.delete_all
  end

  def second_day_at_nine
    event_timezone_at(9) + 1.day
  end

  def event_timezone_at(hour)
    @event.start_date.to_time.in_time_zone(@event.time_zone).change({ hour: hour, min: 0})
  end

  it '.new' do
    csi = ScheduleItem.new(@schedule_attributes)
    expect(csi.class).to eq(ScheduleItem)
  end

  it '.update' do
    schedule = ScheduleItem.new(@schedule_attributes.merge(name: 'Original title')).schedule

    params = @schedule_attributes.merge(name: 'New title')
    new_schedule = ScheduleItem.update(schedule, params)

    expect(new_schedule['name']).to eq('New title')
  end

  describe '.new(params).schedule' do
    it '.set_default_location sets the room according to the event type & location' do
      new_event_type = Global.event.types.third
      @event.event_type = new_event_type
      @event.save

      item = ScheduleItem.new(@new_params.merge(event_id: @event.id)).schedule

      new_room = Global.location.rooms.send(@event.location).send(new_event_type)
      expect(item.location).to eq(new_room)
    end

    it 'creates a valid schedule item without associated lecture item' do
      @schedule = ScheduleItem.new(@schedule_attributes).schedule

      expect(@schedule).to be_valid
      expect(@schedule.lecture_id).to be_nil
    end

    it 'creates a valid schedule item with associated lecture with no person record' do
      @schedule_attributes[:lecture_attributes] = { }
      schedule = ScheduleItem.new(@schedule_attributes).schedule

      expect(schedule.class).to eq(Schedule)
      expect(schedule).to be_valid
    end

    it 'creates a valid schedule item with associated lecture with a person record' do
      @schedule_attributes[:lecture_attributes] = { person_id: @person.id }
      schedule = ScheduleItem.new(@schedule_attributes).schedule

      expect(schedule).to be_valid
      expect(schedule.lecture).to be_valid
      expect(schedule.lecture.class).to eq(Lecture)
    end

    context "Default length of time" do
      before :each do
        @event.schedules.destroy_all
        @event.lectures.destroy_all
      end

      it 'is 60 minutes if there are no previously scheduled lectures' do
        new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id)).schedule

        expect((new_item.end_time - new_item.start_time).to_i / 60).to eq(60)
      end

      it 'is the same length as the lecture scheduled at the same time the previous day' do
        end_time = second_day_at_nine + 23.minutes
        @schedule_attributes[:lecture_attributes] = { person_id: @person.id }
        first_item = ScheduleItem.new(@schedule_attributes.merge(end_time: end_time)).schedule
        first_item.save

        second_item_start = second_day_at_nine + 1.day
        @new_params[:lecture_attributes] = { person_id: @person.id }
        second_item = ScheduleItem.new(@new_params.merge(start_time: second_item_start, name: 'Second item')).schedule

        expect(second_item.end_time).to eq(first_item.end_time + 1.day)
      end

      it 'is the modal length of all previous lectures' do
        @schedule_attributes[:lecture_attributes] = { person_id: @person.id }
        item = ScheduleItem.new(@schedule_attributes).schedule
        item.save # 60 minutes

        3.times do |i| # 30 minutes each
          i += 1
          new_start = item.start_time + i.days + 1.hour
          new_end = new_start + 30.minutes
          new_attributes = @schedule_attributes.merge(start_time: new_start, end_time: new_end)
          new_attributes[:lecture_attributes] = { person_id: @person.id }
          new_item = ScheduleItem.new(new_attributes).schedule
          new_item.save
        end

        start_time = second_day_at_nine + 4.days
        attributes = @new_params.merge(start_time: start_time, end_time: nil)
        attributes[:lecture_attributes] = { person_id: @person.id }
        test_item = ScheduleItem.new(attributes).schedule

        expect(test_item.end_time).to eq(test_item.start_time + 30.minutes)
      end
    end

    context "Default start time" do
      before :each do
        @event.schedules.destroy_all
        @event.lectures.destroy_all
      end

      it 'is 09:00 if there are no other scheduled items' do
        params = @new_params
        params.delete :start_date

        new_item = ScheduleItem.new(params).schedule

        expect(new_item.start_time).to eq(event_timezone_at(9))
      end

      it 'is the end time of the last scheduled item before 09:00 on the same day' do
        attributes = @schedule_attributes.merge(start_time: second_day_at_nine - 2.hours,
                                                  end_time: second_day_at_nine - 1.hour)
        previous_item1 = Schedule.create(attributes)
        attributes = @schedule_attributes.merge(start_time: previous_item1.end_time,
                                                end_time: previous_item1.end_time + 30.minutes)
        previous_item2 = Schedule.create(attributes)

        attributes = @new_params.merge(start_time: second_day_at_nine, end_time: nil)
        new_item = ScheduleItem.new(attributes).schedule

        expect(new_item.start_time).to eq(previous_item2.end_time)
      end

      context "There are no scheduled Lectures on the given day" do

        context "and there is a scheduled non-lecture after 09:30" do
          it "should set the start_time to 09:00" do
            schedule = Schedule.create!(@schedule_attributes.
                          merge(start_time: "#{@event.start_date} 17:00", end_time: "#{@event.start_date} 17:30"))
            new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id)).schedule
            expect(new_item.start_time).to eq(event_timezone_at(9))
          end

          it "unless there are preceding items, then it should use the first available slot" do
            schedule1 = Schedule.create!(@schedule_attributes.
                        merge(start_time: "#{@event.start_date} 09:35", end_time: "#{@event.start_date} 10:00"))
            schedule2 = Schedule.create!(@schedule_attributes.
                       merge(start_time: "#{@event.start_date} 09:00", end_time: "#{@event.start_date} 09:15"))

            new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id)).schedule
            expect(new_item.start_time).to eq(schedule2.end_time)

            schedule3 = Schedule.create!(@schedule_attributes.
                       merge(start_time: "#{@event.start_date} 09:15", end_time: "#{@event.start_date} 09:35"))

            new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id)).schedule
            expect(new_item.start_time).to eq(schedule1.end_time)
          end
        end

        context "there are scheduled lectures on other days" do
          it "should set the start_time to the most popular start time" do
            day = @event.start_date + 1.day
            lecture_time = day.to_time.in_time_zone(@event.time_zone).change({ hour: 14, min: 0})
            lecture1 = create(:lecture, event: @event, start_time: lecture_time, end_time: lecture_time + 30.minutes)
            create(:schedule, event: @event, lecture: lecture1, start_time: lecture1.start_time, end_time: lecture1.end_time)

            lecture2 = create(:lecture, event: @event, start_time: lecture_time + 1.day, end_time: lecture_time + 1.day + 30.minutes)
            create(:schedule, event: @event, lecture: lecture2, start_time: lecture2.start_time, end_time: lecture2.end_time)

            other_lecture_time = (lecture_time + 2.days) - 3.hours
            lecture3 = create(:lecture, event: @event, start_time: other_lecture_time, end_time: other_lecture_time + 30.minutes)
            create(:schedule, event: @event, lecture: lecture3, start_time: lecture3.start_time, end_time: lecture3.end_time)

            new_lecture_day = day + 3.days
            expect(Schedule.select {|s| s.start_time.to_date == new_lecture_day.to_date }).to be_empty

            new_item_params = @new_params.merge(start_time: new_lecture_day)
            new_item = ScheduleItem.new(new_item_params).schedule
            s = Schedule.create(new_item.attributes)
            expect(s.start_time.hour).to eq(14)
          end
        end

      end

      context "There are scheduled Lectures on the given day," do
        before :each do
          @day = second_day_at_nine + 1.day
          @event.schedule_on(@day).each do |item|
            item.delete
          end
          @lecture_attributes = build(:lecture, event: @event).attributes
          @lecture_time = @day.change({ hour: 14, min: 0})

          @lecture1 = Lecture.new(@lecture_attributes.merge(start_time: @lecture_time, end_time: @lecture_time.change({ hour: 14, min: 30})))
          create(:schedule, event: @event, lecture: @lecture1, start_time: @lecture1.start_time, end_time: @lecture1.end_time)
        end

        it "it should set the start_time to the end_time of the last scheduled lecture" do
          new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id, start_time: @day)).schedule
          expect(new_item.start_time).to eq(@lecture1.end_time)
        end

        context "and there is a non-lecture scheduled immediately after the lecture" do
          before do
            @item1 = create(:schedule, event: @event, start_time: @lecture1.end_time, end_time: @lecture1.end_time + 30.minutes)
          end

          it "it should set the start_time to the end_time of the non-lecture item" do
            new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id, start_time: @day)).schedule
            expect(new_item.start_time).to eq(@item1.end_time)
          end

          it "even if there is more than one non-lecture scheduled back-to-back after the lecture" do
            item2 = create(:schedule, event: @event, start_time: @item1.end_time, end_time: @item1.end_time + 30.minutes)
            new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id, start_time: @day)).schedule
            expect(new_item.start_time).to eq(item2.end_time)

            item3 = create(:schedule, event: @event, start_time: item2.end_time, end_time: item2.end_time + 45.minutes)
            new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id, start_time: @day)).schedule
            expect(new_item.start_time).to eq(item3.end_time)
          end
        end

        context "and there is a non-lecture scheduled after the preceding lecture, but not immediately after" do
          before do
            @item1 = create(:schedule, event: @event, start_time: @lecture1.end_time + 60.minutes, end_time: @lecture1.end_time + 90.minutes)
          end

          it "it should set the start_time to the end_time of the previous lecture (not after the non-lecture)" do
            new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id, start_time: @day)).schedule
            expect(new_item.start_time).to eq(@lecture1.end_time)
          end
        end
      end
    end
  end
end