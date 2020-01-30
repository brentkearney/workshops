# app/models/membership.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.
#
class Membership < ApplicationRecord
  attr_accessor :sync_memberships, :update_by_staff, :update_remote, :is_rsvp

  belongs_to :event
  belongs_to :person
  accepts_nested_attributes_for :person
  has_one :invitation, dependent: :delete
  serialize :invite_reminders, Hash

  before_save :set_billing, :set_guests
  after_save :update_counter_cache
  after_update :notify_staff
  after_commit :sync_with_legacy
  before_destroy :delete_on_legacy
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
  validate :check_max_observers
  validate :arrival_and_departure_dates
  validate :guest_disclaimer_acknowledgement
  validate :has_country_if_confirmed

  ROLES = ['Contact Organizer', 'Organizer', 'Participant', 'Observer',
           'Backup Participant'].freeze
  ATTENDANCE = ['Confirmed', 'Invited', 'Undecided', 'Not Yet Invited',
                'Declined'].freeze

  include MembershipDecorators
  include SharedDecorators



  private

  def set_billing
    return unless billing.blank? && !self.person.country.blank?
    country = is_usa?(self.person.country) ? 'USA' : self.person.country
    self.billing = GetSetting.billing_code(self.event.location, country)
  end

  def set_guests
    self.num_guests = 1 if has_guest && num_guests == 0
    self.has_guest = true if num_guests > 0
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

  # max_participants - (invited + confirmed participants)
  def check_max_participants
    return if sync_memberships
    return if attendance == 'Declined' || attendance == 'Not Yet Invited'
    return if event_id.nil?

    invited = event.num_invited_participants.to_i
    return if event.max_participants.to_i - invited >= 0
    errors.add(:attendance, "- the maximum number of invited participants for
               #{event.code} has been reached.".squish)
  end

  def check_max_observers
    return if sync_memberships
    return unless role == 'Observer'
    observers = event.num_invited_observers
    return if observers <= event.max_observers
    errors.add(:attendance, "- the maximum number of invited observers for
               #{event.code} has been reached.".squish)
  end

  def arrival_and_departure_dates
    return true if attendance == 'Declined'
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

      return if update_by_staff || sync_memberships
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

      return if update_by_staff || sync_memberships
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

  def guest_disclaimer_acknowledgement
    return if update_by_staff == true
    if has_guest && guest_disclaimer == false
      errors.add(:guest_disclaimer, "must be acknowledged if bringing a guest.")
    end
  end

  def has_country_if_confirmed
    return true unless attendance == 'Confirmed'
    if self.person.country.blank?
      errors.add(:person, '- country must be set for confirmed members')
      self.person.errors.add(:country, :invalid)
    end
  end

  def update_counter_cache
    event.confirmed_count = Membership.where("attendance='Confirmed'
      AND event_id=?", event.id).count
    event.data_import = true
    event.save
  end

  def sync_with_legacy
    unless sync_memberships
      SyncMembershipJob.perform_later(id) if update_remote
    end
  end

  def delete_on_legacy
    member = { event_id: event.code, legacy_id: person.legacy_id,
               person_id: person_id, updated_by: updated_by }
    DeleteMembershipJob.perform_later(member) unless sync_memberships
  end

  def notify_staff
    changes = saved_changes.transform_values(&:first)
    MembershipChangeNotice.new(changes, self).run
  end
end
