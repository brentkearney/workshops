# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Lecture < ActiveRecord::Base
  belongs_to :event
  belongs_to :person
  has_one :schedule, :dependent => :destroy

  before_save :clean_data
  after_save :update_legacy_db
  before_destroy :delete_from_legacy_db

  validates :event, :person, :title, :start_time, :end_time, :room, :updated_by, presence: true
  validate :ends_after_begins, unless: :missing_data
  validate :times_use_event_timezone, unless: :missing_data
  validate :times_within_event, unless: :missing_data

  # app/models/concerns/schedule_helpers.rb
  include ScheduleHelpers

  private

  def update_legacy_db
    if Rails.env.production?
      lc = LegacyConnector.new
      remote_id = lc.add_lecture(self)
      self.update_column('legacy_id', remote_id) unless self.legacy_id == remote_id
    end
  end

  def delete_from_legacy_db
    unless Rails.env.test?
      lc = LegacyConnector.new
      lc.delete_lecture(self.legacy_id)
    end
  end

end
