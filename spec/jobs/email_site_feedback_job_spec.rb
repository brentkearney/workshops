# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe EmailSiteFeedbackJob, type: :job do
  describe '#perform' do
    it 'calls on the StaffMailer' do
      membership = double('membership', id: 1)
      allow(Membership).to receive(:find_by_id).and_return(membership)
      allow(StaffMailer).to receive_message_chain(:site_feedback, :deliver_now)

      described_class.new.perform('RSVP', membership.id, 'Hello')

      expect(StaffMailer).to have_received(:site_feedback)
        .with(section: 'RSVP', membership: membership, message: 'Hello')
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue' do
      allow(StaffMailer).to receive_message_chain(:site_feedback, :deliver_now)

      described_class.perform_later(1)

      expect(enqueued_jobs.last[:job]).to eq described_class
    end
  end
end
