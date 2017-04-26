# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class ScheduleItem
  attr_reader :schedule

  def initialize(params)
    @is_new_item = params.delete :new_item
    @params = params
    @schedule = Schedule.new(@params)

    @event = Event.find(@schedule.event_id)
    Time.zone = @event.time_zone
    @todays_schedule = @event.schedule_on(@schedule.start_time)
    @lectures = @event.lectures.order(:start_time)

    build_schedule_item
  end

  def self.get(id)
    @schedule = Schedule.find(id)
    unless @schedule.lecture_id.nil?
      @lecture = @schedule.lecture
      @schedule.name = @lecture.title
      @schedule.description = @lecture.abstract
      @schedule.location = @lecture.room
    end
    @schedule
  end


  def self.update(schedule, params)
    @schedule = schedule
    new_day = params.delete :day

    if params[:lecture_attributes]
      lecture_id = params[:lecture_attributes].delete :id unless params[:lecture_attributes][:id].blank?
      person_id = params[:lecture_attributes].delete :person_id unless params[:lecture_attributes][:person_id].blank?
      do_not_publish = params[:lecture_attributes].delete :do_not_publish unless params[:lecture_attributes][:do_not_publish].blank?
      keywords = params[:lecture_attributes].delete :keywords unless params[:lecture_attributes][:keywords].blank?
    end

    new_schedule = Schedule.new(params.merge(id: @schedule.id, staff_item: @schedule.staff_item))
    if new_schedule.created_at.nil?
      new_schedule.created_at = Time.now
    end
    if new_schedule.updated_at.nil?
      new_schedule.updated_at = Time.now
    end

    if new_day && @schedule.start_time.to_date != new_day.to_date
      new_schedule.start_time = new_schedule.start_time.to_time.change({ month: new_day.to_date.month, day: new_day.to_date.mday })
      new_schedule.end_time = new_schedule.end_time.to_time.change({ month: new_day.to_date.month, day: new_day.to_date.mday })
    end

    unless lecture_id.nil?
      lecture = Lecture.find(lecture_id)
      lecture.start_time = new_schedule.start_time
      lecture.end_time = new_schedule.end_time
      lecture.title = new_schedule.name
      lecture.person = Person.find(person_id) unless person_id.nil?
      lecture.do_not_publish = do_not_publish
      lecture.keywords = keywords
      lecture.updated_by = params[:updated_by]
      new_schedule.name = "#{lecture.person.name}: #{new_schedule.name}"
      lecture.abstract = new_schedule.description
      new_schedule.description = nil
      lecture.room = new_schedule.location
      new_schedule.lecture = lecture
      new_attributes = new_schedule.attributes.merge(lecture_attributes: lecture.attributes.compact).compact
    else
      new_attributes = new_schedule.attributes
    end

    new_attributes
  end

  def self.update_others(original_item, params)
    updated_item = Schedule.new(params)

    original_item.event.schedules.each do |item|
      if item.name == original_item.name &&
        item.start_time.to_time.hour == original_item.start_time.to_time.hour &&
        item.start_time.to_time.min == original_item.start_time.to_time.min

        item.start_time = item.start_time.change({ hour: updated_item.start_time.hour, min: updated_item.start_time.min })
        item.end_time = item.end_time.change({ hour: updated_item.end_time.hour, min: updated_item.end_time.min })
        item.name = updated_item.name
        item.description = updated_item.description
        item.location = updated_item.location
        item.updated_by = updated_item.updated_by
        item.save
      end
    end
  end

  private

  def schedule_lecture_name(person)
    if @params[:name].include?(person.name)
      return @params[:name]
    else
      return "#{person.name}: #{@params[:name]}"
    end
  end

  def check_for_day_change
    new_day = @params.delete :day
    if new_day && @schedule.start_time.to_date != new_day.to_date
      @schedule.start_time = @schedule.start_time.change({ day: new_day.to_date.day })
      @schedule.end_time = @schedule.end_time.change({ day: new_day.to_date.day })
    end
  end

  def build_schedule_item
    # Add New Schedule Item form
    if @is_new_item
      @schedule.lecture = Lecture.new(event: @event)
      @schedule.location = set_default_location
      @schedule.start_time = set_default_start_time
      @schedule.end_time = set_default_end_time

    # Form was posted without nested lecture
    elsif @params[:lecture_attributes].blank? || @params[:lecture_attributes][:person_id].blank?
      @schedule.lecture = nil
      check_for_day_change

    # Form was posted with nested lecture
    else
      person = Person.find(@params[:lecture_attributes][:person_id])
      @schedule.name = schedule_lecture_name(person)
      @schedule.description = nil
      check_for_day_change

      lecture_attributes = {
          event_id: @params[:event_id],
          person_id: person.id,
          start_time: @schedule.start_time,
          end_time: @schedule.end_time,
          title: @params[:name],
          abstract: @params[:description],
          room: @params[:location],
          keywords: @params[:lecture_attributes][:keywords],
          do_not_publish: @params[:lecture_attributes][:do_not_publish],
          updated_by: @params[:updated_by]
      }
      @schedule.lecture = Lecture.new(lecture_attributes)
    end

  end

  def set_default_start_time
    phour, pminute = most_popular_start_time.split(':')
    start_time = @schedule.start_time.to_time.in_time_zone(@event.time_zone).change({ hour: phour, min: pminute })

    unless @todays_schedule.empty?
      todays_lectures = @todays_schedule.select {|s| s unless s.lecture_id.nil? }
      if todays_lectures.empty?
        if @todays_schedule.first.start_time < start_time
          start_time = @todays_schedule.first.end_time
        end
        start_time = find_next_free(start_time)
      else
        start_time = todays_lectures.last.end_time
        start_time = find_next_free(start_time)
      end
    end

    start_time
  end

  def most_popular_start_time
    if @lectures.empty?
      return '9:00'
    else
      times = Hash.new(0)
      last_day = 9
      @lectures.pluck(:start_time, :end_time).each do |t|
        item_start, item_end = t
        if item_start.wday != last_day
          times["#{item_start.hour}:#{item_start.min}"] += 1
        end
        last_day = item_start.wday
      end
      times.sort_by{|k, v| v}.last.first
    end
  end

  def find_next_free(start_time)
    while slot_taken(start_time)
      start_time = slot_taken(start_time).end_time
    end
    start_time
  end

  def slot_taken(start_time)
    @todays_schedule.select {|item| item.start_time == start_time}.first
  end

  def set_default_end_time
    # Use the most common lecture length used in this event
    end_time = most_probable_end_time

    # If end_time pushes into the next scheduled item, set it to the start time of that item
    unless @todays_schedule.empty?
      next_item = @todays_schedule.select {|item| item.start_time > @schedule.start_time}.first
      if next_item && end_time > next_item.start_time
        end_time = next_item.start_time
      end
    end

    end_time
  end

  def most_probable_end_time
    same_time_yesterday || start_plus_most_frequent
  end

  def same_time_yesterday
    end_time = false
    @lectures.each do |lecture|
      if lecture.start_time == @schedule.start_time - 1.days
        end_time = lecture.end_time + 1.days
      end
    end
    end_time
  end

  def start_plus_most_frequent
    @schedule.start_time + most_frequent_length
  end

  def most_frequent_length
    if @lectures.empty?
      return 60.minutes
    else
      times = Hash.new(0)
      @lectures.pluck(:start_time, :end_time).each do |t|
        item_start, item_end = t
        lecture_length = (item_end - item_start).abs.to_i / 60
        times[lecture_length] += 1
      end
      mfl, num = times.sort_by{|k, v| v}.last
      mfl.minutes
    end
  end

  def set_default_location
    rooms = Setting.get_all['Rooms']
    location = ''
    unless rooms.nil? || rooms[@event.location].nil?
      location = rooms[@event.location][@event.event_type]
    end
    location
  end
end
