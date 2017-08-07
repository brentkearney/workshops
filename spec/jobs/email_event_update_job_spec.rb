# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe EmailEventUpdateJob, type: :job do
  describe "#perform" do
    it "calls on the StaffMailer" do
      event = double('event', id: 1)
      allow(Event).to receive(:find).and_return(event)
      allow(StaffMailer).to receive_message_chain(:event_update, :deliver_now)
      args = { short_name: 'Short', updated_by: 'Rspec' }

      described_class.new.perform(event.id, args)

      expect(StaffMailer).to have_received(:event_update)
        .with(event, args: args)
    end
  end

  describe ".perform_later" do
    it "adds the job to the queue :urgent" do
      allow(StaffMailer).to receive_message_chain(:event_update, :deliver_now)

      described_class.perform_later(1)

      expect(enqueued_jobs.last[:job]).to eq described_class
    end
  end
end
