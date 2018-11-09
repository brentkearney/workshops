# app/jobs/email_invitation_job.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Initiates InvitationMailer to invite participants
class EmailInvitationJob < ApplicationJob
  queue_as :urgent

  rescue_from(SparkPostRails::DeliveryException) do |exception|
    invitation_id = arguments[0]
    invitation = Invitation.find_by_id(invitation_id)
    person = invitation.membership.person
    event = invitation.membership.event
    msg = { error: "Error sending invitation to #{person.name} for #{event.code}
                    (invitation.id: #{invitation_id})".squish,
            exception: exception }
    StaffMailer.notify_sysadmin(nil, msg).deliver_now
  end

  def perform(invitation_id)
    invitation = Invitation.find_by_id(invitation_id)
    InvitationMailer.invite(invitation).deliver_now
  end
end
