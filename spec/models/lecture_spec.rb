# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe Lecture, type: :model do
  before :each do
    @event = build(:event)
    @lecture = build(:lecture, event: @event,
      start_time: (@event.start_date + 1.days).to_time.change({ hour: 9, min: 0}),
      end_time: (@event.start_date + 1.days).to_time.change({ hour: 10, min: 0}))
  end

  it 'has valid factory' do
    expect(@lecture).to be_valid
  end

  it 'is invalid without an event' do
    @lecture.event = nil
    expect(@lecture).not_to be_valid
    expect(@lecture.errors).to include(:event)
  end

  it 'is invalid without a person' do
    @lecture.person = nil
    expect(@lecture).not_to be_valid
    expect(@lecture.errors).to include(:person)
  end

  it 'is invalid without a title' do
    @lecture.title = nil
    expect(@lecture).not_to be_valid
    expect(@lecture.errors).to include(:title)
  end

  it 'is invalid without a start time' do
    @lecture.start_time = nil
    expect(@lecture).not_to be_valid
    expect(@lecture.errors).to include(:start_time)
  end

  it 'is invalid without an end time' do
    @lecture.end_time = nil
    expect(@lecture).not_to be_valid
    expect(@lecture.errors).to include(:end_time)
  end

  it 'is invalid without a room' do
    @lecture.room = nil
    expect(@lecture).not_to be_valid
    expect(@lecture.errors).to include(:room)
  end

  it 'is invalid without updated_by' do
    @lecture.updated_by = nil
    expect(@lecture).not_to be_valid
    expect(@lecture.errors).to include(:updated_by)
  end

  it 'strips leading and trailing whitespace' do
    @lecture.title = ' To be or not to be '
    @lecture.abstract = 'Yes  '
    @lecture.save
    expect(@lecture.title).to eq('To be or not to be')
    expect(@lecture.abstract).to eq('Yes')
  end

  it 'strips HTML tags from the title' do
    @lecture.title = 'I <em>love</em> ribs'
    @lecture.save
    expect(@lecture.title).to eq('I love ribs')
  end

  it 'is invalid if the start time is outside of the event\'s dates' do
    expect(@lecture).to be_valid
    @lecture.start_time = (@event.start_date - 2.days).to_time
    expect(@lecture).not_to be_valid
    expect(@lecture.errors).to include(:start_time)

    @lecture.start_time = (@event.start_date + 1.days).to_time
    expect(@lecture).to be_valid

    @lecture.start_time = (@event.end_date + 1.days).to_time
    expect(@lecture).not_to be_valid
    expect(@lecture.errors).to include(:start_time)
  end

  it 'is invalid if the end time is outside of the event\'s dates' do
    expect(@lecture).to be_valid
    @lecture.end_time = (@event.end_date + 1.days + 11.hours).to_s(:db)
    expect(@lecture).not_to be_valid
    expect(@lecture.errors).to include(:end_time)
  end

  it 'is invalid if the end time is before the start time' do
    expect(@lecture).to be_valid
    @lecture.start_time = (@event.start_date + 2.days).to_time
    @lecture.end_time = (@event.start_date + 1.days).to_time
    expect(@lecture).not_to be_valid
    expect(@lecture.errors).to include(:end_time)
  end

  it 'is invalid if the end time is equal to the start time (causes infinite loop!)' do
    lecture = build(:lecture, event: @event, start_time: @event.start_date.at_midday, end_time: @event.start_date.at_midday)

    expect(lecture).not_to be_valid
    expect(lecture.errors.full_messages).to eq(['End time - must be greater than start time'])
  end

  context 'if times overlap with another scheduled lecture' do
    before do
      @lecture1 = @lecture
    end

    it 'is invalid if the start time is >= other start time and < other end time' do
      lecture2 = Lecture.new(@lecture1.attributes.
          merge(id: 666, start_time: @lecture1.start_time + 5.minutes, end_time: @lecture1.end_time - 5.minutes))
      expect(lecture2).not_to be_valid
    end

    it 'is valid if the start time is == other end time' do
      lecture2 = Lecture.new(@lecture1.attributes.
          merge(id: 666, event: @lecture.event, start_time: @lecture1.end_time, end_time: @lecture1.end_time + 5.minutes))

      expect(lecture2).to be_valid
    end

    it 'is invalid if the end time is > other start_time and < other end_time' do
      lecture2 = Lecture.new(@lecture1.attributes.
          merge(id: 666, end_time: @lecture1.start_time + 5.minutes))
      expect(lecture2).not_to be_valid
    end

    it 'is valid if the end time is == other start time' do
      lecture2 = Lecture.new(@lecture1.attributes.
          merge(id: 666, event: @lecture.event, start_time: @lecture1.start_time - 25.minutes, end_time: @lecture1.start_time))

      expect(lecture2).to be_valid
    end

    it 'is invalid if the start time is < other start time and the end time is > other start time' do
      lecture2 = Lecture.new(@lecture1.attributes.
          merge(id: 666, start_time: @lecture1.start_time - 5.minutes, end_time: @lecture1.start_time + 5.minutes))
      expect(lecture2).not_to be_valid
    end

    it 'does not invalidate because it overlaps with itself' do
      expect(@lecture1).to be_valid
      @lecture1.start_time = @lecture1.start_time + 5.minutes
      expect(@lecture1).to be_valid
    end

  end
end
