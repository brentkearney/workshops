# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe 'Model validations: Schedule', type: :model do
  before do
    Event.destroy_all
    @event = create(:event)
  end

  before :each do
    @schedule = create(:schedule, event: @event,
      start_time: (@event.start_date + 1.days).to_time.change({ hour: 9, min: 0}),
      end_time: (@event.start_date + 1.days).to_time.change({ hour: 10, min: 0}))
  end

  it 'has valid factory' do
    expect(@schedule).to be_valid
  end

  it 'is invalid without a name' do
    @schedule.name = nil
    expect(@schedule).not_to be_valid
    expect(@schedule.errors).to include(:name)
  end

  it 'is invalid without a start time' do
    @schedule.start_time = nil
    expect(@schedule).not_to be_valid
    expect(@schedule.errors).to include(:start_time)
  end

  it 'is invalid without an end time' do
    expect(@schedule).to be_valid
    @schedule.end_time = nil
    expect(@schedule).not_to be_valid
    expect(@schedule.errors).to include(:end_time)
  end

  it 'is invalid without a location' do
    expect(@schedule).to be_valid
    @schedule.location = nil
    expect(@schedule).not_to be_valid
    expect(@schedule.errors).to include(:location)
  end

  it 'is invalid without updated_by' do
    expect(@schedule).to be_valid
    @schedule.updated_by = nil
    expect(@schedule).not_to be_valid
    expect(@schedule.errors).to include(:updated_by)
  end

  context 'if times overlap with another scheduled item' do
    before do
      @schedule1 = @schedule
      expect(@schedule1).to be_valid
    end

    it 'if the start time is >= other start time and < other end time, it produces a warning' do
      schedule2 = Schedule.new(@schedule1.attributes.
        merge(id: 666, start_time: @schedule1.start_time + 5.minutes, end_time: @schedule1.end_time - 5.minutes))
      expect(schedule2).to be_valid
      expect(schedule2.flash_notice).not_to be_empty
      expect(schedule2.flash_notice[:warning]).to include('overlaps with')
    end

    it 'is valid if the start time is == other end time' do
      schedule2 = Schedule.new(@schedule1.attributes.
        merge(id: 666, start_time: @schedule1.end_time, end_time: @schedule1.end_time + 5.minutes))

      expect(schedule2).to be_valid
    end

    it 'if the end time is > other start_time and < other end_time, it produces a warning' do
      schedule2 = Schedule.new(@schedule1.attributes.
        merge(id: 666, end_time: @schedule1.start_time + 5.minutes))
      expect(schedule2).to be_valid
      expect(schedule2.flash_notice).not_to be_empty
      expect(schedule2.flash_notice[:warning]).to include('overlaps with')
    end

    it 'is valid if the end time is == other start time' do
      schedule2 = Schedule.new(@schedule1.attributes.
        merge(id: 666, start_time: @schedule1.start_time - 25.minutes, end_time: @schedule1.start_time))
      expect(schedule2).to be_valid
    end

    it 'if the start time is < other start time and the end time is > other start time, it produces a warning' do
      schedule2 = Schedule.new(@schedule1.attributes.
        merge(id: 666, start_time: @schedule1.start_time - 5.minutes, end_time: @schedule1.start_time + 5.minutes))
      expect(schedule2).to be_valid
      expect(schedule2.flash_notice).not_to be_empty
      expect(schedule2.flash_notice[:warning]).to include('overlaps with')
    end

    it 'does not invalidate because it overlaps with itself' do
      expect(@schedule1).to be_valid
      @schedule1.start_time = @schedule1.start_time + 5.minutes
      expect(@schedule1).to be_valid
    end
  end

  it 'is invalid if the start time is outside of the event\'s dates' do
    schedule = build(:schedule)
    schedule.start_time = (schedule.event.start_date - 1.days + 11.hours).to_s(:db)
    expect(schedule).not_to be_valid
    schedule.start_time = (schedule.event.end_date + 1.days + 11.hours).to_s(:db)
    expect(schedule).not_to be_valid
  end

  it 'is invalid if the end time is outside of the event\'s dates' do
    schedule = build(:schedule, event: @event)
    schedule.start_time = (@event.end_date - 1.days).to_time.change({ hour: 9, min: 0})
    schedule.end_time = (@event.end_date + 1.days).to_time.change({ hour: 9, min: 0})
    expect(schedule).not_to be_valid
    expect(schedule.errors).not_to include(:start_time)
    expect(schedule.errors).to include(:end_time)
  end

  it 'is invalid if the end time is before the start time' do
    schedule = build(:schedule)
    schedule2 = Schedule.new(schedule.attributes.merge(start_time: schedule.end_time + 60.minutes,
      end_time: schedule.end_time + 30.minutes))
    expect(schedule2).not_to be_valid
    expect(schedule2.errors.full_messages).to eq(['End time - must be greater than start time'])
  end

  it 'is invalid if the end time is equal to the start time (causes infinite loop!)' do
    schedule = build(:schedule)
    schedule2 = Schedule.new(schedule.attributes.merge(start_time: schedule.end_time + 60.minutes, end_time: schedule.end_time + 60.minutes))
    expect(schedule2).not_to be_valid
    expect(schedule2.errors.full_messages).to eq(['End time - must be greater than start time'])
  end

  it 'accepts nested attributes for Lecture' do
    lecture = build(:lecture, event: @event,
      start_time: (@event.start_date + 1.days).to_time.change({ hour: 9, min: 0}),
      end_time: (@event.start_date + 1.days).to_time.change({ hour: 10, min: 0}))
    @schedule.lecture = lecture
    expect(@schedule).to be_valid
  end

  context '.notify_staff?' do
    it 'true if event is current' do
      event = build(:event, current: true)
      schedule = build(:schedule, event: event, staff_item: true,
        start_time: Time.now, end_time: Time.now + 30.minutes)

      expect(schedule.notify_staff?).to be_truthy
    end

    it 'false if event is not current' do
      event = build(:event, past: true)
      schedule = build(:schedule, event: event, staff_item: false,
        start_time: Time.now, end_time: Time.now + 30.minutes)

      expect(schedule.notify_staff?).to be_falsey
    end
  end
end
