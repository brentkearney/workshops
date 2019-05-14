# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Returns scheduled lectures, for RSS feeds
class GetLectures
  attr_reader :todays_lectures

  def initialize(room)
    @room = room
    @todays_lectures = lectures_on(Date.current)
    unless @todays_lectures.empty?
      @time_zone = @todays_lectures.first.event.time_zone
      @tolerance = calculate_tolerance(@todays_lectures)
    end
  end

  def lectures_on(date)
    Lecture.where(start_time: date.beginning_of_day..date.end_of_day)
                         .where(room: @room).order(:start_time)
  end

  # Nearest talk to present time, within tolerance range
  def current
    now = Time.current.in_time_zone(@time_zone)

    lectures = {}
    @todays_lectures.each do |lecture|
      next unless lecture.filename.blank? # skip if already recorded
      lecture_time = lecture.start_time.in_time_zone(@time_zone)
      next if lecture_time < now - @tolerance
      next if lecture_time > now + @tolerance
      lectures[ lecture.id ] = (lecture_time.to_i - now.to_i).abs
    end
    return '' if lectures.empty?
    Lecture.find(lectures.key(lectures.values.min))
  end

  # returns the first lecture in the next 15 days
  def next
    now = Time.current.in_time_zone(@time_zone) - @tolerance
    (0..15).each do |n|
      day = DateTime.current + n.days
      lectures_on(day).each do |lecture|
        lecture_time = lecture.start_time.in_time_zone(@time_zone)
        return lecture if lecture_time > now
      end
    end
  end

  # Set tolerance to half of the average time of talks today, plus 1 minute
  def calculate_tolerance(lectures)
    return 0 if lectures.empty?
    lecture_lengths = []
    lectures.each do |item|
      lecture_lengths << item.end_time.to_i - item.start_time.to_i
    end
    average_seconds = lecture_lengths.inject{ |sum, time| sum + time }.to_f /
      lecture_lengths.size
    (average_seconds / 60 / 2).to_i.minutes + 1.minute
  end
end
