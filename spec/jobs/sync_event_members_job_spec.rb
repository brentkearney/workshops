# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe SyncEventMembersJob, type: :job do
  let(:event) { create(:event) }
  subject(:job) { SyncEventMembersJob.perform_later(event) }

  it 'queues the job' do
    expect { job }
      .to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it 'is in urgent queue' do
    expect(SyncEventMembersJob.new.queue_name).to eq('urgent')
  end

  it 'executes perform' do
    expect(SyncMembers).to receive(:new).with(event)
    perform_enqueued_jobs { job }
  end

  it 'queues retry given no results error' do
    allow(LegacyConnector).to receive(:new).and_return(FakeLegacyConnector.new)
    allow(SyncMembers).to receive(:new).and_raise('NoResultsError')

    perform_enqueued_jobs do
      expect_any_instance_of(SyncEventMembersJob)
        .to receive(:retry_job).with(wait: 5.minutes, queue: :default)
      job
    end
  end

  after :each do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
