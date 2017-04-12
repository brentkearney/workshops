# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Membership < ActiveRecord::Base
  belongs_to :event
  belongs_to :person
  accepts_nested_attributes_for :person
  has_one :invitation

  attr_accessor :sync_remote
  after_update :attendance_notification, :sync_with_legacy
  after_save :update_counter_cache
  after_destroy :update_counter_cache

  validates :event, presence: true
  validates :person, presence: true, :uniqueness => { :scope => :event,
      :message => "is already a participant of this event" }
  validates :updated_by, presence: true

  validate :set_role
  validate :default_attendance
  validate :check_max_participants
  validate :arrival_and_departure_dates

  ROLES = ['Contact Organizer', 'Organizer', 'Participant', 'Observer', 'Backup Participant']
  ATTENDANCE = ['Confirmed', 'Invited', 'Undecided', 'Not Yet Invited', 'Declined']

  def update_counter_cache
    self.event.confirmed_count = Membership.where("attendance='Confirmed' AND event_id=?", self.event.id).count
    self.event.save
  end

  def shares_email?
    self.share_email
  end

  def is_org?
    self.role == 'Organizer' || self.role == 'Contact Organizer'
  end

  def set_role
    unless ROLES.include?(role)
      self.role = 'Participant'
    end
  end

  def default_attendance
    unless Membership::ATTENDANCE.include?(attendance)
      self.attendance = 'Not Yet Invited'
    end
  end

  def arrival_and_departure_dates
    if self.event.blank?
      errors.add(:event, "can't be blank")
      return false
    else
      w = Event.find(self.event.id)
    end

    unless arrival_date.blank?
      if arrival_date.to_date > w.end_date.to_date
        errors.add(:arrival_date, "- arrival date must be before the end of the event.")
      end
      if (arrival_date.to_date - w.start_date.to_date).to_i.abs >= 30
        errors.add(:arrival_date, "- arrival date must be within 30 days of the event.")
      end
    end

    unless departure_date.blank?
      if departure_date.to_date < w.start_date.to_date
        errors.add(:departure_date, "- departure date must be after the beginning of the event.")
      end
    end

    if errors.empty?
      return false
    else
      return true
    end
  end

  # max_participants - (invited + confirmed participants)
  def check_max_participants
    if attendance == 'Declined' || attendance == 'Not Yet Invited'
      return true
    else
      unless event_id.nil?
        unless event.max_participants.to_i - event.num_invited_participants.to_i >= 0
          errors.add(:attendance, "- the maximum number of invited participants for #{event.code} has been reached.")
        end
      end
    end
  end

  def attendance_notification
    if self.changed.include?('attendance')
      old_attendance = self.attendance_was
      new_attendance = self.attendance

      msg = nil
      msg = 'is no longer confirmed' if old_attendance == 'Confirmed'
      msg = 'is now confirmed' if new_attendance == 'Confirmed'

      OrganizerMailer.attendance_change(self, old_attendance, new_attendance).deliver_now
      StaffMailer.confirmation_notice(self, msg).deliver_now unless msg.nil?
    end
  end

  def sync_with_legacy
    LegacyConnector.new.update_member(self) if sync_remote
  end

end
