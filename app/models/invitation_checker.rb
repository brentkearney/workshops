# app/models/invitation_checker.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

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

  def event
    invitation.is_a?(Invitation) ? invitation.event : nil
  end

  def check_legacy_database
    invitation = nil
    response = LegacyConnector.new.check_rsvp(@otp)

    @errors.add(:Invitation, response['denied']) if response['denied']
    @errors.add(:Event, 'No event associated') if response['event_code'].blank?
    @errors.add(:Person, 'No person associated') if response['legacy_id'].blank?

    unless @errors.any?
      event = Event.find(response['event_code'])
      if event.nil?
        @errors.add(:Event, 'Error finding event record')
        return nil
      end

      SyncEventMembersJob.perform_now(event.id) unless event.nil?
      sleep 1

      person = Person.where(legacy_id: response['legacy_id'].to_i).first
      if person.nil?
        @errors.add(:Person, 'Error finding person record')
        return nil
      end

      membership = Membership.where(person: person, event: event).first
      if membership.nil?
        @errors.add(:Membership, 'Error finding event membership')
        return nil
      else
        invitation = create_local_invitation(membership)
      end
    end
    invitation
  end

  def validate(invitation)
    if invitation.nil?
      @errors.add(:Invitation, 'That invitation code was not found.')
    end
    return if invitation.nil?

    if invitation.expires && DateTime.now > invitation.expires
      @errors.add(:Invitation, 'This invitation code is expired.')
    end

    if Date.today > invitation.membership.event.end_date
      @errors.add(:Event, "You cannot RSVP for past events.")
    end

    case invitation.membership.attendance
    when 'Declined'
      @errors.add(:Membership, "You have already declined an invitation
            to this event. Please contact the event's organizers to ask if it
            is still possible to attend.")

    when 'Not Yet Invited'
      @errors.add(:Membership, ": The event's organizers have not yet
        invited you. Please contact them if you wish to be invited.")
    end

    unless @errors.empty?
      @errors.each do |k, v|
        invitation.errors.add(k.to_sym, v.to_s)
      end
    end
  end

  def create_local_invitation(membership)
    invitation = Invitation.new(membership: membership, invited_by: 'Staff',
                                code: local_otp)
    invitation.save
    invitation
  end
end
