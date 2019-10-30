# app/forms/invitation_checker.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Works with invitation_form
class InvitationChecker
  attr_reader :otp, :invitation, :errors

  def initialize(otp)
    @otp = otp
    @errors = ActiveModel::Errors.new(self)
    @invitation = find_invitation
  end

  def find_invitation
    invitation = Invitation.find_by_code(local_otp) || check_legacy_database
    validate(invitation) if invitation
    invitation || self
  end

  def local_otp
    @otp.length < 50 ? @otp.ljust(50, '-') : @otp
  end

  def reload
    @invitation = Invitation.find_by_code(@otp)
  end

  def event
    invitation.is_a?(Invitation) ? invitation.event : nil
  end

  def check_response_errors(response)
    @errors.add(:Invitation, response['denied']) if response['denied']
    @errors.add(:Event, 'No event associated') if response['event_code'].blank?
    @errors.add(:Person, 'No person associated') if response['legacy_id'].blank?
  end

  def check_legacy_database
    response = LegacyConnector.new.check_rsvp(@otp)
    check_response_errors(response)
    return if @errors.any?

    event = find_event(response['event_code']) || return
    sync_event_members(event)
    person = find_person(response['legacy_id'].to_i) || return
    membership = find_membership(person, event) || return
    create_local_invitation(membership)
  end

  def find_event(event_code)
    event = Event.find_by_code(event_code)
    @errors.add(:Event, 'Error finding event record') if event.blank?
    event
  end

  def find_membership(prsn, event)
    mbr = Membership.where(person: prsn, event: event).first
    @errors.add(:Membership, 'Error finding membership') if mbr.nil?
    mbr
  end

  def find_person(person_id)
    prsn = Person.where(legacy_id: person_id).first ||
      @errors.add(:Person, 'Error finding person record')
    prsn
  end

  def sync_event_members(event)
    return if event.blank?
    if event.start_date > Date.current
      SyncEventMembersJob.perform_now(event.id)
    end
  end

  def validate(invitation)
    return if nil_invitation?(invitation)
    check_invitation_expiry(invitation)
    check_past_event(invitation)
    check_attendance(invitation)

    unless @errors.empty?
      @errors.each do |k, v|
        invitation.errors.add(k.to_sym, v.to_s)
      end
    end
  end

  def check_past_event(invitation)
    if Time.zone.today > invitation.membership.event.end_date
      @errors.add(:Event, "You cannot RSVP for past events.")
    end
  end

  def check_invitation_expiry(invitation)
    if invitation.expires && DateTime.now > invitation.expires
      @errors.add(:Invitation, 'This invitation code is expired.')
    end
  end

  def nil_invitation?(invitation)
    if invitation.nil?
      @errors.add(:Invitation, 'That invitation code was not found.')
      return true
    end
  end

  def check_attendance(invitation)
    case invitation.membership.attendance
    when 'Declined'
      @errors.add(:Membership, "You have already declined an invitation
            to this event. Please contact the event's organizers to ask if it
            is still possible to attend.")

    when 'Not Yet Invited'
      @errors.add(:Membership, ": The event's organizers have not yet
        invited you. Please contact them if you wish to be invited.")
    end
  end

  def create_local_invitation(membership)
    invitation = Invitation.new(membership: membership, invited_by: 'Staff',
                                code: local_otp)
    invitation.save
    invitation
  end
end
