require 'rails_helper'

RSpec.describe SendParticipantConfirmationJob, type: :job do
  describe "#perform" do
    it "calls on the ParticipantMailer" do
      membership = double("membership", id: 1)
      allow(Membership).to receive(:find).and_return(membership)
      allow(ParticipantMailer).to receive_message_chain(:rsvp_confirmation, :deliver_now)

      described_class.new.perform(membership.id)

      expect(ParticipantMailer).to have_received(:rsvp_confirmation)
    end
  end

  describe ".perform_later" do
    it "adds the job to the queue :rsvp_confirm" do
      allow(ParticipantMailer).to receive_message_chain(:rsvp_confirmation, :deliver_now)

      described_class.perform_later(1)

      expect(enqueued_jobs.last[:job]).to eq described_class
    end
  end
end
