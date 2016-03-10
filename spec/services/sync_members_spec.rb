# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe "SyncMembers" do
  before :each do
    Event.destroy_all
    Person.destroy_all
  end

  it '.initialize' do
    event = create(:event_with_members)
    # expect(LegacyConnector).to receive(:new).and_return(FakeLegacyConnector.new)

    sm = SyncMembers.new(event)

    expect(sm.event).to eq(event)
    # expect(sm.remote_members).not_to be_empty
    expect(sm.sync_errors).to be_a(ErrorReport)
  end

  describe '.get_remote_members' do
    context 'with no remote members' do
      before do
        @new_event = create(:event, code: '09w6666')
        @sm = SyncMembers.new(@new_event)
      end

      it 'raises an error message' do
        expect(LegacyConnector).to receive(:new).and_return(FakeLegacyConnector.new)
        expect { @sm.get_remote_members }.to raise_error('NoResultsError')
      end

      it 'adds a message to sync_errors' do
        expect(LegacyConnector).to receive(:new).and_return(FakeLegacyConnector.new)
        expect { @sm.get_remote_members }.to raise_error('NoResultsError')
        expect(@sm.sync_errors.errors["FakeLegacyConnector"].last.message).to eq("Unable to retrieve any remote members for #{@new_event.code}")
      end

    end

    context 'with remote members' do

    end
  end

end