# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Schedule < ActiveRecord::Base
  belongs_to :event
  belongs_to :lecture
  accepts_nested_attributes_for :lecture
  attr_accessor :day
  attr_accessor :flash_notice

  before_save :clean_data

  validates :event, :location, :updated_by, presence: true
  validates_associated :lecture, allow_nil: true
  validates :name, presence: true
  validates :start_time, :end_time, presence: true

  validate :ends_after_begins, unless: :missing_data
  validate :times_use_event_timezone, unless: :missing_data
  validate :times_within_event, unless: :missing_data
  validate :times_do_not_overlap, unless: :missing_data

  # app/models/concerns/schedule_helpers.rb
  include ScheduleHelpers

  def day
    start_time.to_date
  end

  private

  def overlaps_message(other)
    "\"#{other.name}\" in #{other.location} @ #{other.start_time.strftime('%H:%M')} - #{other.end_time.strftime('%H:%M')}"
  end

  def errors_or_warnings(field, other)
    if location == other.location
      msg = '<strong>Same time and location as:</strong> '
      msg << overlaps_message(other)
      errors.add(field, msg)
    else
      if self.flash_notice.blank? || self.flash_notice[:warning].blank?
        self.flash_notice = {:warning => "\"#{self.name}\" (#{self.location}) " +
            "overlaps with these items: <ul>\n\t<li>" +
            "#{overlaps_message(other)}" +
            "</li>\n</ul>" }
      else
        unless self.flash_notice[:warning].include? overlaps_message(other)
          self.flash_notice[:warning] = "#{self.flash_notice[:warning]}"[0...-5] #remove </ul>
          self.flash_notice[:warning] <<  "\t<li>#{overlaps_message(other)}</li>\n</ul>"
        end
      end
    end
  end

  def times_do_not_overlap
    Schedule.where("to_char(start_time, 'YYYY-MM-DD') = ? AND event_id = ? AND id != ?",
                    self.start_time.strftime('%Y-%m-%d'),
                    self.event_id,
                    self.id.nil? ? 0 : self.id
    ).each do |other|

      if start_time < other.start_time && end_time > other.start_time
        errors_or_warnings(:end_time, other)
      end

      if start_time >= other.start_time && start_time < other.end_time
        errors_or_warnings(:start_time, other)
      end

    end
  end

end

