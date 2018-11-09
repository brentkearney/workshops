# app/models/lecture.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Lecture < ApplicationRecord
  belongs_to :event
  belongs_to :person
  has_one :schedule, dependent: :destroy

  before_save :clean_data, :strip_html
  after_save :update_legacy_db
  before_destroy :delete_from_legacy_db

  validates :event, :person, :title, :start_time, :end_time, :room, :updated_by, presence: true
  validate :ends_after_begins, unless: :missing_data
  validate :times_use_event_timezone, unless: :missing_data
  validate :times_within_event, unless: :missing_data
  validate :times_overlap, unless: :missing_data

  # app/models/concerns/schedule_helpers.rb
  include ScheduleHelpers

  private

  def strip_html
    self.title = ActionController::Base.helpers.strip_tags(title)
  end

  def add_error(field, other)
    if room == other.room
      msg = '<strong>cannot overlap with another lecture in the same room:</strong> '
      msg << "#{other.person.name} in #{other.room} at #{other.start_time.strftime('%H:%M')} - #{other.end_time.strftime('%H:%M')}"
      errors.add(field, msg)
    end
  end

  def update_legacy_db
    if Rails.env.production?
      lc = LegacyConnector.new
      remote_id = lc.add_lecture(self)
      self.update_column(:legacy_id, remote_id) unless self.legacy_id == remote_id
    end
  end

  def delete_from_legacy_db
    if Rails.env.production?
      lc = LegacyConnector.new
      lc.delete_lecture(self.legacy_id)
    end
  end

end
