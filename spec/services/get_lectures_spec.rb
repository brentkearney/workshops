# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe "GetLectures" do
  context '.initialize' do
    before do
      @event = add_lectures_on(Date.current)
      @room = Lecture.last.room
    end

    it 'initializes with room parameter' do
      gl = GetLectures.new(@room)
      expect(gl).to be_a(GetLectures)
    end

    it 'sets todays_lectures' do
      gl = GetLectures.new(@room)
      expect(gl.todays_lectures).not_to be_empty
    end

    it 'survives empty lectures' do
      Lecture.destroy_all
      gl = GetLectures.new(@room)
      expect(gl.todays_lectures).to eq([])
    end
  end

  context '.on/.lectures_on' do
    before do
      @next_month = Date.current + 1.month
      @room = 'Empty'
      @event = add_lectures_on(@next_month, @room)
    end

    it 'returns the lectures on the given day' do
      lectures = GetLectures.on(@next_month, @room)
      expect(lectures.size).to eq(4)
    end

    it 'returns an empty array if there are no lectures' do
      Lecture.destroy_all
      expect(GetLectures.on(Date.current)).to eq([])
    end
  end

  context '.current' do
    before do
      @room = 'Empty'
      @event = create(:event, start_date: Date.today,
                                end_date: Date.today + 5.days)
    end

    it 'returns the lecture closest to the current time' do
      start_time = Time.current - 1.hour
      end_time = start_time + 30.minutes
      create(:lecture, event: @event, start_time: start_time,
                    end_time: end_time, room: @room)
      create(:lecture, event: @event, start_time: start_time + 2.hours,
                    end_time: end_time + 2.hours, room: @room)
      lecture = create(:lecture, event: @event, room: @room,
                           start_time: Time.current - 10.minutes,
                           end_time: Time.current + 20.minutes)

      gl = GetLectures.new(@room)
      expect(gl.current).to eq(lecture)
    end

    it 'returns an empty string if there are no lectures' do
      Lecture.destroy_all
      expect(GetLectures.new(@room).current).to eq('')
    end
  end

  context '.next' do
    before do
      @room = 'Auditorium'
    end

    it 'returns the next lecture today' do
      start_time = DateTime.current + 2.hours
      end_time = start_time + 30.minutes
      event = create(:event, start_date: Date.today,
                               end_date: Date.today + 5.days)
      lecture = create(:lecture, start_time: start_time, event: event,
                       end_time: end_time, room: @room)

      next_lecture = GetLectures.new(@room).next
      expect(next_lecture).to eq(lecture)
      lecture.destroy
    end

    it 'returns the next lecture within 15 days' do
      start_time = Time.current + 3.days
      end_time = start_time + 30.minutes
      event = create(:event, start_date: start_time - 1.day,
                               end_date: end_time + 4.days)
      lecture = create(:lecture, start_time: start_time, event: event,
                       end_time: end_time, room: @room)

      next_lecture = GetLectures.new(@room).next
      expect(next_lecture).to eq(lecture)
      lecture.destroy
    end

    it 'returns nil if there is no next lecture within 15 days' do
      start_time = Time.current + 16.days
      end_time = start_time + 30.minutes
      event = create(:event, start_date: start_time - 1.day,
                               end_date: end_time + 4.days)
      lecture = create(:lecture, start_time: start_time, event: event,
                       end_time: end_time, room: @room)

      next_lecture = GetLectures.new(@room).next
      expect(next_lecture).to be_nil
      lecture.destroy
    end
  end
end
