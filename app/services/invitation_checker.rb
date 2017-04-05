# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class InvitationChecker
  attr_reader :otp, :invitation, :errors

  def initialize(otp)
    @otp = otp
    @invitation = nil
    @errors = ActiveModel::Errors.new(self)
  end

  def invitation
    local_otp = @otp
    local_otp = otp.ljust(50, '-') if otp.length < 50
    @invitation = Invitation.find_by_code(local_otp) || check_legacy_database
  end

  def check_legacy_database
    invitation = nil
    response = LegacyConnector.new.check_rsvp(@otp)
    Rails.logger.debug "\nLegacy response: #{response.inspect}\n"
    unless response['event_code'].nil? || response['legacy_id'].nil?
      event = Event.find(response['event_code'])
      # temporary, until members are added using Workshops
      SyncEventMembersJob.perform_now(event) unless event.nil?
      sleep 2
      person = Person.where(legacy_id: response['legacy_id']).first
      membership = Membership.where(person: person, event: event).first

      unless invalid_membership?(membership)
        invitation = create_local_invitation(membership)
      end
    end
    invitation
  end

  def invalid_membership?(membership)
    membership.nil? || membership.attendance == 'Declined'
  end

  def create_local_invitation(membership)
    invitation = Invitation.new(membership: membership, invited_by: 'Staff',
      code: @otp.ljust(50, '-'), expires: Date.tomorrow)
    invitation.save
    invitation
  end

end
