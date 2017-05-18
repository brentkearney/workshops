# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'
include ActiveJob::TestHelper

describe 'Event Sync Happens in Background', type: :feature do
  before do
    authenticate_user
    @event = create(:event)
  end

  it 'runs a background job to sync data when event page is accessed' do
    expect(SyncEventMembersJob).to receive(:perform_later).once
    visit event_path(@event)
  end

end
