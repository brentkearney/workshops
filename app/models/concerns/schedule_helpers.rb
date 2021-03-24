# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module ScheduleHelpers
  extend ActiveSupport::Concern

  def notify_staff?
    event.current?
  end

    # Convert to event's time zone
  def self.start_time
    super.in_time_zone(self.event.time_zone) if super && self.event.time_zone
  end

  def self.end_time
    super.in_time_zone(self.event.time_zone) if super && self.event.time_zone
  end

  def times_use_event_timezone
    unless start_time.nil? || end_time.nil? || event.nil?
      start_time.time_zone.name == event.time_zone &&
          end_time.time_zone.name == event.time_zone
    end
  end

  def times_within_event
    schedule_start = start_time.to_time.in_time_zone(event.time_zone).to_i
    schedule_end = end_time.to_time.in_time_zone(event.time_zone).to_i
    event_start = event.start_date.to_time.in_time_zone(event.time_zone).to_i
    event_end = event.end_date.to_time.in_time_zone(event.time_zone).change({ hour: 23 }).to_i

    if schedule_start < event_start || schedule_start > event_end
      errors.add(:start_time, "- must be within the event dates")
    end

    if schedule_end < event_start || schedule_end > event_end
      errors.add(:end_time, "- must be within the event dates")
    end
  end

  def missing_data
    event.blank? || start_time.blank? || end_time.blank?
  end

  def ends_after_begins
    if end_time <= start_time
      errors.add(:end_time, "- must be greater than start time")
    end
  end

  # Schedule items can overlap, but not Lectures
  def errors_or_warnings(field, other)
    if self.is_a?(Schedule)
      add_overlaps_warning(other)
    else
      field = 'time' if field.to_s.match?("_time")
      add_error(field, other)
    end
  end

  def times_overlap
    self.class.where("((start_time, end_time) OVERLAPS
                      (timestamp :start, timestamp :end)) AND id != :myself",
                      :start => self.start_time, :end => self.end_time,
                      :myself => self.id.nil? ? 0 : self.id
    ).order(:start_time).each { |other| errors_or_warnings(:start_time, other) }
  end

  def clean_data
    # remove leading & trailing whitespace
    attributes.each_value { |v| v.strip! if v.respond_to? :strip! }
  end
end
