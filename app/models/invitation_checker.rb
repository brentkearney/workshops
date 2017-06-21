# Copyright (c) 2016 Banff International Research Station
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

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

  def check_legacy_database
    invitation = nil
    response = LegacyConnector.new.check_rsvp(@otp)
    Rails.logger.debug "\nLegacy response: #{response.inspect}\n"

    @errors.add(:Invitation, response['denied']) if response['denied']
    @errors.add(:Event, 'No event associated') if response['event_code'].blank?
    @errors.add(:Person, 'No person associated') if response['legacy_id'].blank?

    unless @errors.any?
      event = Event.find(response['event_code'])
      if event.nil?
        @errors.add(:Event, 'Error finding event record')
        return nil
      end

      # temporary, until members are added using Workshops
      SyncEventMembersJob.perform_now(event) unless event.nil?
      sleep 2

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
