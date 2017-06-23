# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Initiates StaffMailer to confirm RSVPs
class EmailInvitationJob < ActiveJob::Base
  queue_as :urgent

  def perform(invitation_id)
    invitation = Invitation.find_by_id(invitation_id)
    InvitationMailer.invite(invitation).deliver_now
  end
end
