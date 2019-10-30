# app/jobs/email_invitation_job.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Initiates InvitationMailer to send invitationr reminder to participants
class EmailInvitationReminderJob < ApplicationJob
  queue_as :urgent

  def perform(invitation_id)
    invitation = Invitation.find_by_id(invitation_id)
    InvitationMailer.reinvite(invitation).deliver_now
  end
end
