# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Returns scheduled lectures, for RSS feeds
class GetLectures
  def initialize(room)
    @room = room
  end

  def self.on(date, room = @room)
    Lecture.where(start_time: date.beginning_of_day..date.end_of_day)
                         .where(room: room).order(:start_time)
  end

  def lectures_on(date, room = @room)
    GetLectures.on(date, room)
  end

  def todays_lectures
    lectures_on(Date.current)
  end

  def find_timezone
    lecture = Lecture.where(room: @room).first
    return lecture.event.time_zone unless lecture.nil?
    GetSetting.default_timezone
  end

  # Nearest talk to present time, within tolerance range
  def current
    time_zone = find_timezone
    now = Time.current.in_time_zone(time_zone)
    lectures = todays_lectures
    tolerance = calculate_tolerance(lectures)

    lecture_ids = {}
    lectures.each do |lecture|
      next unless lecture.filename.blank? # skip if already recorded
      lecture_time = lecture.start_time.in_time_zone(time_zone)
      next if lecture_time < now - tolerance
      next if lecture_time > now + tolerance
      lecture_ids[ lecture.id ] = (lecture_time.to_i - now.to_i).abs
    end
    return '' if lecture_ids.empty?
    lectures.select {|l| l.id == lecture_ids.key(lecture_ids.values.min) }.last
  end

  # returns the first lecture in the next 15 days
  def next
    time_zone = find_timezone
    lectures = todays_lectures
    now = Time.current.in_time_zone(time_zone) - calculate_tolerance(lectures)
    lecture = lectures.select {|l| l.start_time.in_time_zone(time_zone) > now }.first
    return lecture unless lecture.blank?

    (1..15).each do |n|
      day = DateTime.current.in_time_zone(time_zone) + n.days
      lectures_on(day).each do |dlecture|
        lecture_time = dlecture.start_time.in_time_zone(time_zone)
        return dlecture if lecture_time > now
      end
    end
    nil
  end

  # returns the last lecture of the day
  def last(date = Time.zone.today)
    Lecture.where(start_time: date.beginning_of_day..date.end_of_day)
                         .where(room: @room).order(:start_time).last
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
