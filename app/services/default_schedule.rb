# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# DefaultSchedule creates a default schedule for events that have none
class DefaultSchedule
  attr_reader :schedules

  def initialize(event, user)
    @event = event
    @current_user = user
    @schedules = schedule_with_lectures

    if @current_user
      if @schedules.empty? && is_authorized?
        build_default_schedule
      end
    else
      @schedules = Array.new unless @event && @event.publish_schedule
    end
  end

  private

  def is_authorized?
    @current_user.is_organizer?(@event) || @current_user.is_admin? ||
        (@current_user.is_staff? && @current_user.location == @event.location)
  end

  def build_default_schedule
    template_event = Event.where(template: true, location: @event.location, event_type: @event.event_type).first

    unless template_event.nil?
      template_schedules = template_event.schedules.order(:start_time)
    end

    unless template_schedules.blank?
      used_items = []
      @event.days.each do |eday|
        template_schedules.each do |item|
          unless used_items.include?(item)
            if item.start_time.wday == eday.wday
              @event.schedules.create!(item.attributes.
                 merge(id: nil,
                       event_id: @event.id,
                       start_time: item.start_time.change({ year: eday.year, month: eday.month, day: eday.mday }),
                       end_time: item.end_time.change({ year: eday.year, month: eday.month, day: eday.mday }),
                       created_at: Time.now,
                       updated_at: Time.now,
                       updated_by: 'Default Schedule'
              ))
              used_items << item
            end
          end
        end
      end
    end

    @schedules = @event.schedules.order(:start_time)
  end

  def schedule_with_lectures
    if @event
      @schedules = @event.schedules.order(:start_time, 'lecture_id DESC').includes(:lecture)
    else
      @schedules = Array.new
    end

    unless @schedules.empty?
      @schedules.each_with_index do |item, index|
        if item.lecture && item.lecture.abstract
          item.description = item.lecture.abstract
        end
        @schedules[index] = item
      end
    end
    @schedules
  end

end