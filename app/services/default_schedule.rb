# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# DefaultSchedule creates a default schedule for events that have none
class DefaultSchedule
  attr_reader :schedules, :event

  def initialize(event, user)
    @event = event
    @current_user = user
    @schedules = collect_event_schedule

    build_default_schedule if authorized?
  end

  private

  def authorized?
    Pundit.policy(@current_user, self).allow?
  end

  def empty_or_default
    @schedules.empty? || only_default_entries
  end

  def only_default_entries
    defaults = @schedules.select { |s| s.updated_by == 'Default Schedule' }
    @event.schedules.destroy_all if (@schedules - defaults).empty?
  end

  def build_default_schedule
    return unless empty_or_default
    template_event = Event.where(template: true, location: @event.location,
                                 event_type: @event.event_type).first
    return if template_event.nil?

    template_schedules = template_event.schedules.order(:start_time)
    return if template_schedules.blank?

    used_items = []
    @event.days.each do |eday|
      template_schedules.each do |item|
        next if used_items.include?(item)
        next if item.start_time.wday != eday.wday
        @event.schedules.create!(item.attributes
          .merge(id: nil,
                 event_id: @event.id,
                 start_time: item.start_time
                                 .change(year: eday.year,
                                         month: eday.month,
                                         day: eday.mday),
                 end_time: item.end_time
                               .change(year: eday.year,
                                       month: eday.month,
                                       day: eday.mday),
                 created_at: Time.now,
                 updated_at: Time.now,
                 updated_by: 'Default Schedule'))
        used_items << item
      end
    end

    @schedules = @event.schedules.order(:start_time)
  end

  def collect_event_schedule
    schedules = []
    return schedules unless published_schedule
    schedules = @event.schedules.order(:start_time,
                                       'lecture_id DESC').includes(:lecture)
    add_lectures(schedules)
  end

  def add_lectures(schedules)
    schedules.each_with_index do |item, index|
      if item.lecture && item.lecture.abstract
        item.description = item.lecture.abstract
      end
      schedules[index] = item
    end
    schedules
  end

  def published_schedule
    return false unless @event
    authorized? || @event.publish_schedule
  end
end
