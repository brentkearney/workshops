# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe EmailScheduleChangeNoticeJob, type: :job do
  describe '#perform' do
    before do
      allow(StaffMailer).to receive_message_chain(:schedule_change,
                                                  :deliver_now)
    end

    it 'calls on the StaffMailer with :create' do
      schedule = double('schedule', id: 1)
      args = { type: :create, original_schedule: schedule, user: 'Rspec' }

      described_class.new.perform(args)

      expect(StaffMailer).to have_received(:schedule_change)
        .with(args)
    end

    it 'calls on the StaffMailer with :update' do
      original_schedule = double('schedule', id: 1)
      updated_schedule = double('schedule', id: 1)
      args = { type: :update, user: 'Rspec',
               original_schedule: original_schedule,
               updated_schedule: updated_schedule,
               changed_similar: false }

      described_class.new.perform(args)

      expect(StaffMailer).to have_received(:schedule_change)
        .with(args)
    end

    it 'calls on the StaffMailer with :destroy' do
      schedule = double('schedule', id: 1)
      args = { type: :destroy, original_schedule: schedule, user: 'Rspec' }

      described_class.new.perform(args)

      expect(StaffMailer).to have_received(:schedule_change)
        .with(args)
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue :urgent' do
      allow(StaffMailer).to receive_message_chain(:schedule_change,
                                                  :deliver_now)

      described_class.perform_later(1)

      expect(enqueued_jobs.last[:job]).to eq described_class
    end
  end
end
