# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Initiates ParticipantMailer to confirm RSVPs
class EmailParticipantConfirmationJob < ActiveJob::Base
  queue_as :urgent

  def perform(membership_id)
    membership = Membership.find_by_id(membership_id)
    ParticipantMailer.rsvp_confirmation(membership).deliver_now
  end
end
