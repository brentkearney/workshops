# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe "ScheduleItem" do

  before do
    @user = authenticate_user
    @event = FactoryGirl.create(:event)
    @schedule_attributes = { :event_id => @event.id,
                             :start_time => (@event.start_date + 1.days).to_time.in_time_zone(@event.time_zone).change({ hour: 9, min: 0}),
                             :end_time =>  (@event.start_date + 1.days).to_time.in_time_zone(@event.time_zone).change({ hour: 10, min: 0}),
                             :name =>  'Good morning!',
                             :description =>  'The first item of the day.',
                             :location => 'TCPL 201',
                             :updated_by => "RSpec" }

    @new_params = {new_item: true, event_id: @event.id, start_time: @event.start_date.to_time, updated_by: @user.name}
  end

  after(:each) do
    Warden.test_reset!
  end

  after do
    Lecture.delete_all
    Schedule.delete_all
  end

  it "accepts a hash of schedule attributes" do
    CSI = ScheduleItem.new(@schedule_attributes)
    expect(CSI.class).to eq(ScheduleItem)
  end

  describe "Updates existing Schedule Items" do
    it 'accepts a schedule object and new params' do
      schedule = ScheduleItem.new(@schedule_attributes.merge(name: 'Original title')).schedule
      # original_schedule = Schedule.create!(schedule.attributes)
      # expect(original_schedule.name).to eq('Original title')

      params = @schedule_attributes.merge(name: 'New title')
      new_schedule = ScheduleItem.update(schedule, params)
      expect(new_schedule['name']).to eq('New title')
    end
  end

  describe "Creates new Schedule Items" do
    it ".set_default_location sets location based on event_type" do
      @event.event_type = 'Research in Teams'
      @event.save

      item = ScheduleItem.new(@new_params.merge(event_id: @event.id)).schedule
      expect(item.location).to eq('TCPL 107')

      @event.event_type = 'Focussed Research Group'
      @event.save
      new_params = {new_item: true, event_id: @event.id, start_time: @event.start_date.to_time, updated_by: @user.name}
      schedule = ScheduleItem.new(new_params).schedule
      expect(schedule.location).to eq('TCPL 202')

      @event.event_type = '5 Day Workshop'
      @event.save
      new_params = {new_item: true, event_id: @event.id, start_time: @event.start_date.to_time, updated_by: @user.name}
      schedule = ScheduleItem.new(new_params).schedule
      expect(schedule.location).to eq('TCPL 201')
    end

    context "With no nested lecture_attributes" do
      before do
        @schedule = ScheduleItem.new(@schedule_attributes).schedule
      end

      it "should create a schedule item without an associated lecture" do
        expect(@schedule.lecture_id).to be_nil
      end

      it "should create a valid schedule object" do
        expect(@schedule).to be_valid
      end

    end

    context "With nested lecture_attributes" do
      before do
        @schedule_attributes[:lecture_attributes] = { }
      end

      context "without a person_id" do
        it "should create a valid (non-lecture) schedule object" do
          schedule = ScheduleItem.new(@schedule_attributes).schedule
          expect(schedule.class).to eq(Schedule)
          expect(schedule).to be_valid
        end
      end

      context "with a person_id" do
        it "should create a valid schedule and associated lecture object" do
          person = FactoryGirl.create(:person)
          @schedule_attributes[:lecture_attributes] = { :person_id => person.id }
          schedule = ScheduleItem.new(@schedule_attributes).schedule

          expect(schedule).to be_valid
          expect(schedule.lecture).to be_valid
        end
      end
    end

    context "With reasonable default length of time, if" do
      context "there are no previously scheduled lectures" do
        before :each do
          @event.schedules.delete_all
        end

        it "should set the length to 60 minutes" do
          new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id)).schedule
          expect((new_item.end_time - new_item.start_time).to_i / 60).to eq(60)
        end
      end

      context "there are previously scheduled lectures" do
        before do
          @event.schedules.delete_all
          @day = @event.start_date + 1.days
          lecture_attributes = FactoryGirl.build(:lecture, event: @event).attributes
          (9..12).each do |t|
            lecture_time = @day.to_time.in_time_zone(@event.time_zone).change({ hour: t, min: 0})
            lecture = Lecture.new(lecture_attributes.merge(start_time: lecture_time, end_time: lecture_time + 30.minutes))
            FactoryGirl.create(:schedule, event: @event, lecture: lecture, start_time: lecture.start_time, end_time: lecture.end_time)
          end
        end

        it "should use the same length of a lecture scheduled at the same time the previous day" do
          previous_start = (@day + 1.days).to_time.in_time_zone(@event.time_zone).change({ hour: 9, min: 0 })
          previous_end = (@day + 1.days).to_time.in_time_zone(@event.time_zone).change({ hour: 9, min: 23 })
          previous_item = FactoryGirl.create(:lecture, event_id: @event.id, start_time: previous_start, end_time: previous_end)

          new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id, start_time: (@day + 2.days).to_time.in_time_zone(@event.time_zone).change({ hour: 9, min: 0 }))).schedule
          s = Schedule.create(new_item.attributes)
          expect(s.end_time).to eq(((@day + 2.days).to_time.in_time_zone(@event.time_zone).change({ hour: 9, min: 23})).in_time_zone(@event.time_zone))
        end

        it "if theres no item at the same time the previous day, it should use the modal length" do
          new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id, start_time: (@day + 3.days))).schedule
          expect((new_item.end_time - new_item.start_time).to_i / 60).to eq(30)
        end
      end
    end

    context "With a reasonable default start_time, if" do
      
      context "There are no scheduled Lectures on the given day" do
        before :each do
          @event.schedule_on(@event.start_date).each do |item|
            item.delete
          end
        end

        context "and there are no scheduled non-lectures either" do
          it "should set the start_time to 09:00" do
            new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id)).schedule
            expect(new_item.start_time).to eq(@event.start_date.to_time.in_time_zone(@event.time_zone).change({ hour: 9, min: 0}))
          end
        end

        context "and there is a scheduled non-lecture before 09:00" do
          it "should set the start_time to the end_time of the non-lecture" do
            schedule = Schedule.create!(@schedule_attributes.
                          merge(start_time: "#{@event.start_date} 08:00", end_time: "#{@event.start_date} 08:30"))
            new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id)).schedule
            expect(new_item.start_time).to eq(schedule.end_time)
          end

          it "even if there is more than one non-lecture prior to 9" do
            schedule = Schedule.create!(@schedule_attributes.
                                            merge(start_time: "#{@event.start_date} 08:00", end_time: "#{@event.start_date} 08:30"))
            schedule2 = Schedule.create!(@schedule_attributes.
                                            merge(start_time: "#{@event.start_date} 08:30", end_time: "#{@event.start_date} 08:45"))
            new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id)).schedule
            expect(new_item.start_time).to eq(schedule2.end_time)
          end
        end

        context "and there is a scheduled non-lecture after 09:30" do
          it "should set the start_time to 09:00" do
            schedule = Schedule.create!(@schedule_attributes.
                          merge(start_time: "#{@event.start_date} 17:00", end_time: "#{@event.start_date} 17:30"))
            new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id)).schedule
            expect(new_item.start_time).to eq(@event.start_date.to_time.in_time_zone(@event.time_zone).change({ hour: 9, min: 0}))
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
            lecture1 = FactoryGirl.create(:lecture, event: @event, start_time: lecture_time, end_time: lecture_time + 30.minutes)
            FactoryGirl.create(:schedule, event: @event, lecture: lecture1, start_time: lecture1.start_time, end_time: lecture1.end_time)

            lecture2 = FactoryGirl.create(:lecture, event: @event, start_time: lecture_time + 1.day, end_time: lecture_time + 1.day + 30.minutes)
            FactoryGirl.create(:schedule, event: @event, lecture: lecture2, start_time: lecture2.start_time, end_time: lecture2.end_time)

            other_lecture_time = (lecture_time + 2.days) - 3.hours
            lecture3 = FactoryGirl.create(:lecture, event: @event, start_time: other_lecture_time, end_time: other_lecture_time + 30.minutes)
            FactoryGirl.create(:schedule, event: @event, lecture: lecture3, start_time: lecture3.start_time, end_time: lecture3.end_time)

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
          @day = @event.start_date + 2.days
          @event.schedule_on(@day).each do |item|
            item.delete
          end
          @lecture_attributes = FactoryGirl.build(:lecture, event: @event).attributes
          @lecture_time = @day.to_time.in_time_zone(@event.time_zone).change({ hour: 14, min: 0})

          @lecture1 = Lecture.new(@lecture_attributes.merge(start_time: @lecture_time, end_time: @lecture_time.change({ hour: 14, min: 30})))
          FactoryGirl.create(:schedule, event: @event, lecture: @lecture1, start_time: @lecture1.start_time, end_time: @lecture1.end_time)
        end

        it "it should set the start_time to the end_time of the last scheduled lecture" do
          #@lecture3 = Lecture.new(@lecture_attributes.merge(start_time: @lecture_time.change({ hour: 14, min: 0}), end_time: @lecture_time.change({ hour: 14, min: 30})))
          #FactoryGirl.create(:schedule, event: @event, lecture: @lecture3, start_time: @lecture3.start_time, end_time: @lecture3.end_time)

          new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id, start_time: @day)).schedule
          expect(new_item.start_time).to eq(@lecture1.end_time)
        end

        context "and there is a non-lecture scheduled immediately after the lecture" do
          before do
            @item1 = FactoryGirl.create(:schedule, event: @event, start_time: @lecture1.end_time, end_time: @lecture1.end_time + 30.minutes)
          end

          it "it should set the start_time to the end_time of the non-lecture item" do
            new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id, start_time: @day)).schedule
            expect(new_item.start_time).to eq(@item1.end_time)
          end

          it "even if there is more than one non-lecture scheduled back-to-back after the lecture" do
            item2 = FactoryGirl.create(:schedule, event: @event, start_time: @item1.end_time, end_time: @item1.end_time + 30.minutes)
            new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id, start_time: @day)).schedule
            expect(new_item.start_time).to eq(item2.end_time)

            item3 = FactoryGirl.create(:schedule, event: @event, start_time: item2.end_time, end_time: item2.end_time + 45.minutes)
            new_item = ScheduleItem.new(@new_params.merge(event_id: @event.id, start_time: @day)).schedule
            expect(new_item.start_time).to eq(item3.end_time)
          end
        end

        context "and there is a non-lecture scheduled after the preceding lecture, but not immediately after" do
          before do
            @item1 = FactoryGirl.create(:schedule, event: @event, start_time: @lecture1.end_time + 60.minutes, end_time: @lecture1.end_time + 90.minutes)
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