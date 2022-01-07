# app/models/lecture.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Lecture < ApplicationRecord
  attr_accessor :from_api, :local_only
  belongs_to :event
  belongs_to :person
  has_one :schedule, dependent: :destroy

  before_save :clean_data, :strip_html
  after_save :update_legacy_db, unless: :local_only
  before_destroy :delete_from_legacy_db

  validates :event, :person, :title, :start_time, :end_time, :room, :updated_by, presence: true
  validate :ends_after_begins, unless: :missing_data
  validate :times_use_event_timezone, unless: :missing_data
  validate :times_within_event, unless: :missing_data
  validate :times_overlap, unless: [:missing_data, :from_api, :in_the_past]

  delegate :url_helpers, to: 'Rails.application.routes'

  # app/models/concerns/schedule_helpers.rb
  include ScheduleHelpers

  private

  def in_the_past
    DateTime.current > end_time
  end

  def strip_html
    self.title = ActionController::Base.helpers.strip_tags(title)
  end

  def link_to_other_event_schedule(other)
    return '' unless other.event_id != self.event_id
    url = "/events/#{other.event.code}/schedule"
    " See the <a href=\"#{url}\"><u>#{other.event.code} schedule</u></a>
    for details."
  end

  def add_error(field, other)
    return unless room == other.room
    msg = '<strong>cannot overlap with another lecture at the same
      location:</strong> '
    msg << "#{other.person.name} at #{other.room} during
      #{other.start_time.strftime('%H:%M')} -
      #{other.end_time.strftime('%H:%M')}."
    msg << link_to_other_event_schedule(other)
    errors.add(field, msg.squish)
  end

  def update_legacy_db
    return unless Rails.env.production?

    remote_id = LegacyConnector.new.add_lecture(self)
    unless remote_id.blank? || remote_id == 0 || self.legacy_id == remote_id
      self.update_column(:legacy_id, remote_id)
    end
  end

  def delete_from_legacy_db
    if Rails.env.production?
      lc = LegacyConnector.new
      lc.delete_lecture(self.legacy_id)
    end
  end

end
