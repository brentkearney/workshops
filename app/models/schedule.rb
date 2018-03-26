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
    if earliest.blank?
      self.earliest = nil
    elsif start_time > earliest
      time_change_warning('start_time')
      self.start_time = earliest
    end

    if latest.blank?
      self.latest = nil
    elsif end_time > latest
      time_change_warning('end_time')
      self.end_time = latest
    end

    return if staff_item
    self.earliest = nil
    self.latest = nil
  end

  def time_change_warning(startend)
    earlylate = startend == 'start_time' ? 'earliest' : 'latest'
    msg = "<p>'#{name}' #{startend.humanize} was changed from "
    msg << "#{send(startend.to_sym).strftime('%H:%M')} to the "
    msg << "#{earlylate} allowed time, "
    msg << "#{send(earlylate.to_sym).strftime('%H:%M')}</p>"
    self.flash_notice = { warning: '' } if flash_notice.blank?
    flash_notice[:warning] << msg.squish
  end

  def overlaps_message(other)
    "“#{other.name}” in #{other.location} @
    #{other.start_time.strftime('%H:%M')} -
     #{other.end_time.strftime('%H:%M')}".squish
  end

  def add_overlaps_warning(other)
    self.flash_notice = { warning: '' } if flash_notice.blank?
    unless flash_notice[:warning].include? 'overlaps with'
      msg = "<p>#{name} (#{location}) @ #{start_time.strftime('%H:%M')} - "
      msg << "#{end_time.strftime('%H:%M')}\" overlaps with these items:</p>\n"
      flash_notice[:warning] << msg.squish
    end
    return if flash_notice[:warning].include? overlaps_message(other)
    flash_notice[:warning] << "#{overlaps_message(other)}<br />\n"
  end
end
