# app/jobs/email_participant_confirmation_job.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Initiates ParticipantMailer to confirm RSVPs
class EmailParticipantConfirmationJob < ApplicationJob
  queue_as :urgent

  # rescue_from(SparkPostRails::DeliveryException) do |exception|
  #   membership_id = arguments[0]
  #   membership = Membership.find_by_id(membership_id)
  #   person = membership.person
  #   event = membership.event
  #   msg = { error: "Error sending RSVP confirmation to #{event.code} Participant
  #                  #{person.name}".squish,
  #           exception: exception }
  #   StaffMailer.notify_sysadmin(nil, msg).deliver_now
  # end

  def perform(membership_id)
    membership = Membership.find_by_id(membership_id)
    ParticipantMailer.rsvp_confirmation(membership).deliver_now
  end
end
