# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Membership < ActiveRecord::Base
  attr_accessor :sync_remote, :update_by_staff

  belongs_to :event
  belongs_to :person, autosave: false
  accepts_nested_attributes_for :person
  has_one :invitation, dependent: :destroy

  after_save :update_counter_cache
  after_update :notify_staff
  after_commit :sync_with_legacy
  after_destroy :update_counter_cache

  validates :event, presence: true
  validates :person, presence: true,
                     uniqueness: { scope: :event,
                                   message: 'is already a participant
                                   of this event'.squish }
  validates :updated_by, presence: true

  validate :set_role
  validate :default_attendance
  validate :check_max_participants
  validate :arrival_and_departure_dates
  validate :guest_disclamer_acknowledgement

  ROLES = ['Contact Organizer', 'Organizer', 'Participant', 'Observer',
           'Backup Participant'].freeze
  ATTENDANCE = ['Confirmed', 'Invited', 'Undecided', 'Not Yet Invited',
                'Declined'].freeze

  def shares_email?
    share_email
  end

  def is_org?
    role == 'Organizer' || role == 'Contact Organizer'
  end

  def arrives
    return 'Not set' if arrival_date.blank?
    arrival_date.strftime('%b %-d, %Y')
  end

  def departs
    return 'Not set' if departure_date.blank?
    departure_date.strftime('%b %-d, %Y')
  end

  def rsvp_date
    return 'N/A' if replied_at.blank?
    replied_at.in_time_zone(event.time_zone).strftime('%b %-d, %Y %H:%M %Z')
  end

  private

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

  # max_participants - (invited + confirmed participants)
  def check_max_participants
    return if attendance == 'Declined' || attendance == 'Not Yet Invited'
    return if event_id.nil?
    invited = event.num_invited_participants.to_i
    return if event.max_participants.to_i - invited >= 0
    errors.add(:attendance, "- the maximum number of invited participants for
               #{event.code} has been reached.".squish)
  end

  def arrival_and_departure_dates
    w = event

    unless arrival_date.blank?
      if arrival_date.to_date > w.end_date.to_date
        errors.add(:arrival_date,
                   '- arrival date must be before the end of the event.')
      end
      if (arrival_date.to_date - w.start_date.to_date).to_i.abs >= 30
        errors.add(:arrival_date,
                   '- arrival date must be within 30 days of the event.')
      end

      return if update_by_staff
      if arrival_date.to_date < w.start_date.to_date
        errors.add(:arrival_date,
                   '- special permission required for early arrival.')
      end
    end

    unless departure_date.blank?
      if departure_date.to_date < w.start_date.to_date
        errors.add(:departure_date,
                   '- departure date must be after the beginning of the event.')
      end

      return if update_by_staff
      if departure_date.to_date > w.end_date.to_date
        errors.add(:departure_date,
                   '- special permission required for late departure.')
      end
    end

    unless arrival_date.blank? || departure_date.blank?
      if arrival_date.to_date > departure_date.to_date
        errors.add(:arrival_date, "- one must arrive before departing!")
      end
    end
  end

  def guest_disclamer_acknowledgement
    if has_guest && !guest_disclaimer
      errors.add(:guest_disclaimer, 'must be acknowledged if bringing a guest.')
    end
  end

  def update_counter_cache
    event.confirmed_count = Membership.where("attendance='Confirmed'
      AND event_id=?", event.id).count
    event.save
  end

  def sync_with_legacy
    SyncMembershipJob.perform_later(id) if sync_remote
  end

  def notify_staff
    MembershipChangeNotice.new(changed, self).run
  end
end
