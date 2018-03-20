# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Schedule < ActiveRecord::Base
  belongs_to :event
  belongs_to :lecture
  accepts_nested_attributes_for :lecture
  attr_accessor :day
  attr_accessor :flash_notice

  before_save :clean_data, :strip_html

  validates :event, :location, :updated_by, presence: true
  validates_associated :lecture, allow_nil: true
  validates :name, presence: true
  validates :start_time, :end_time, presence: true

  validate :time_limits
  validate :ends_after_begins, unless: :missing_data
  validate :times_use_event_timezone, unless: :missing_data
  validate :times_within_event, unless: :missing_data
  validate :times_overlap, unless: :missing_data

  # app/models/concerns/schedule_helpers.rb
  include ScheduleHelpers

  def day
    start_time.to_date unless start_time.nil?
  end

  private

  def strip_html
    self.name = ActionController::Base.helpers.strip_tags(name)
  end

  def time_limits
    Rails.logger.debug '*' * 100 + "\n\n"
    Rails.logger.debug "Schedule model was given:"
    Rails.logger.debug "day: #{day}"
    Rails.logger.debug "start_time: #{start_time}"
    Rails.logger.debug "end_time: #{end_time}"
    Rails.logger.debug "earliest: #{earliest}"
    Rails.logger.debug "latest: #{latest}"
    Rails.logger.debug '*' * 100 + "\n\n"

    if earliest.blank?
      self.earliest = nil
    elsif start_time < earliest
      self.start_time = earliest
    end

    if latest.blank?
      self.latest = nil
    elsif end_time > latest
      self.end_time = latest
    end

    return if staff_item
    self.earliest = nil
    self.latest = nil
  end

  def overlaps_message(other)
    "\"#{other.name}\" in #{other.location} @ #{other.start_time.strftime('%H:%M')} - #{other.end_time.strftime('%H:%M')}"
  end

  def add_warning(field, other)
    if self.flash_notice.blank? || self.flash_notice[:warning].blank?
      self.flash_notice = {:warning => "<span class=\"warning-header\">\"#{self.name} (#{self.location}) @ #{self.start_time.strftime('%H:%M')} - #{self.end_time.strftime('%H:%M')}\" " +
          "overlaps with these items: </span>\n<p>" +
          "#{overlaps_message(other)}" +
          "</p>\n" }
    else
      unless self.flash_notice[:warning].include? overlaps_message(other)
        self.flash_notice[:warning] = "#{self.flash_notice[:warning]}" #[0...-5]
        self.flash_notice[:warning] <<  "<p>#{overlaps_message(other)}</p>\n"
      end
    end
  end

end

