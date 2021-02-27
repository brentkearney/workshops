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

  def perform(invitation_id, template)
    invitation = Invitation.find_by_id(invitation_id)
    mm = InvitationMailer.invite(invitation, template)
    Rails.logger.debug "\n\n************************************************\n\n\n"
    Rails.logger.debug "mandrill_mail response:\n#{mm.deliver_now}\n"
    Rails.logger.debug "\n\n\n************************************************\n\n"
  end
end
