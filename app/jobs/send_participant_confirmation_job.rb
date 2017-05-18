class SendParticipantConfirmationJob < ActiveJob::Base
  queue_as :rsvp_confirm

  def perform(membership_id)
    membership = Membership.find(membership_id)
    ParticipantMailer.rsvp_confirmation(membership).deliver_now
  end
end
