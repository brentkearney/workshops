# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe SyncMembershipJob, type: :job do
  let(:membership) { create(:membership) }
  subject(:job) { SyncMembershipJob.perform_later(membership) }

  it 'queues the job' do
    expect { job }
      .to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it 'is in urgent queue' do
    expect(SyncEventMembersJob.new.queue_name).to eq('urgent')
  end

  it 'executes perform' do
    lc = double('lc')
    allow(LegacyConnector).to receive(:new).and_return(lc)
    allow(lc).to receive(:update_member)

    perform_enqueued_jobs { job }

    expect(lc).to have_received(:update_member).with(membership)
  end

  it 'notifies sysadmin if there is a parse error' do
    lc = double('lc')
    allow(LegacyConnector).to receive(:new).and_return(lc)
    allow(lc).to receive(:update_member).and_raise('JSON::ParserError')

    perform_enqueued_jobs do
      expect_any_instance_of(StaffMailer).to receive(:notify_sysadmin)
      job
    end
  end

  it 'retries later if there is another error' do
    lc = double('lc')
    allow(LegacyConnector).to receive(:new).and_return(lc)
    allow(lc).to receive(:update_member).and_raise('NoResultsError')

    perform_enqueued_jobs do
      expect_any_instance_of(SyncMembershipJob)
        .to receive(:retry_job).with(wait: 10.minutes, queue: :default)
      job
    end
  end

  after :each do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
