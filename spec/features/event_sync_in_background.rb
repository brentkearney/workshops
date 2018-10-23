# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'
include ActiveJob::TestHelper

describe 'Event Sync Happens in Background', type: :feature do
  it 'runs a background job to sync data when event page is accessed' do
    event = create(:event)
    allow_any_instance_of(EventPolicy).to receive(:sync?).and_return(true)
    allow(SyncEventMembersJob).to receive(:perform_later)
    visit event_path(event)
    expect(SyncEventMembersJob).to have_received(:perform_later).with(event.id)
  end
end
