# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe EmailInvalidCodeBounceJob, type: :job do
  describe "#perform" do
    it "calls on the BounceMailer" do
      allow(BounceMailer).to receive_message_chain(:invalid_event_code, :deliver_now)

      described_class.new.perform({})

      expect(BounceMailer).to have_received(:invalid_event_code).with({})
    end
  end

  describe ".perform_later" do
    it "adds the job to the queue :non_member" do
      allow(BounceMailer).to receive_message_chain(:invalid_event_code, :deliver_now)

      described_class.perform_later(1)

      expect(enqueued_jobs.last[:job]).to eq described_class
    end
  end
end
