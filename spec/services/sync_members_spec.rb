# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe "SyncMembers" do
  after :each do
    Event.destroy_all
  end

  it '.initialize' do
    event = create(:event_with_members)
    expect(LegacyConnector).to receive(:new).and_return(FakeLegacyConnector.new)

    sm = SyncMembers.new(event)

    expect(sm.event).to eq(event)
    expect(sm.remote_members).not_to be_empty
    expect(sm.sync_errors).to be_a(ErrorReport)
  end

  describe '.get_remote_members' do
    context 'with no remote members' do
      it 'sends a message to ErrorReport and raises an error message' do
        new_event = create(:event)
        lc = FakeLegacyConnector.new
        expect(LegacyConnector).to receive(:new).and_return(lc)

        expect_any_instance_of(ErrorReport).to receive(:add).with(lc, "Unable to retrieve any remote members for #{new_event.code}")
        expect { @sm = SyncMembers.new(new_event) }.to raise_error('NoResultsError')
      end

      it 'sends email to staff' do
        new_event = create(:event)
        lc = FakeLegacyConnector.new
        expect(LegacyConnector).to receive(:new).and_return(lc)

        expect { @sm = SyncMembers.new(new_event) }.to raise_error('NoResultsError')

        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end
    end

    context 'with remote members' do
      it 'returns the remote members' do
        new_event = create(:event_with_members)
        expect(LegacyConnector).to receive(:new).and_return(FakeLegacyConnector.new)

        sm = SyncMembers.new(new_event)

        expect(sm.remote_members).not_to be_empty
      end
    end
  end

  describe '.fix_remote_fields' do
    it 'fills in blank fields, sets Backup Participant attendance to "Not Yet Invited"' do
      membership = create(:membership)
      event = membership.event
      lc = FakeLegacyConnector.new
      allow(lc).to receive(:get_members).with(event).and_return(lc.get_members_with_changed_fields(event))
      expect(LegacyConnector).to receive(:new).and_return(lc)

      SyncMembers.new(event)
      member = Event.find(event.id).memberships.last

      expect(member.person.updated_by).to eq('Workshops importer')
      expect(member.person.updated_at).not_to be_nil
      expect(member.updated_by).to eq('Workshops importer')
      expect(member.updated_at).not_to be_nil
      expect(member.role).to eq('Backup Participant')
      expect(member.attendance).to eq('Not Yet Invited')
    end
  end

  describe '.update_person' do
    def test_update(local_person)
      event = create(:event)
      membership = create(:membership, event: event, person: local_person)
      lc = FakeLegacyConnector.new
      allow(lc).to receive(:get_members).with(event).and_return(lc.get_members_with_person(event: event, m: membership, lastname: 'Remoteperson'))
      expect(LegacyConnector).to receive(:new).and_return(lc)

      SyncMembers.new(event)

      lp = Person.find(local_person.id)
      expect(lp.lastname).to eq('Remoteperson')
    end

    context 'remote person with a legacy_id' do
      it 'updates the local person' do
        local_person = create(:person, lastname: 'Localperson', legacy_id: 666)
        test_update(local_person)
      end
    end

    context 'remote person without a legacy_id' do
      it 'updates the local person (.get_local_person also uses email address)' do
        local_person = create(:person, lastname: 'Localperson', legacy_id: nil)
        test_update(local_person)
      end
    end

    context 'without a local person' do
      it 'creates a new person record' do
        event = create(:event)
        lc = FakeLegacyConnector.new
        allow(lc).to receive(:get_members).with(event).and_return(lc.get_members_with_person(event: event, m: nil, lastname: 'Remoteperson'))
        expect(LegacyConnector).to receive(:new).and_return(lc)

        SyncMembers.new(event)

        lp = Event.find(event.id).members.last
        expect(lp.lastname).to eq('Remoteperson')
      end
    end
  end

  describe '.save_person' do
    context 'valid person' do
      it 'saves the Person and logs a message' do
        event = create(:event)
        person = create(:person, firstname: 'New', lastname: 'McPerson')
        membership = create(:membership, event: event, person: person)
        lc = FakeLegacyConnector.new
        allow(lc).to receive(:get_members).with(event).and_return(lc.get_members_with_person(event: event, m: membership, lastname: 'McPerson'))
        expect(LegacyConnector).to receive(:new).and_return(lc)

        expect(Rails.logger).to receive(:info).with("\n* Saved #{event.code} person: New McPerson\n")
        SyncMembers.new(event)

        lp = Event.find(event.id).members.last
        expect(lp.name).to eq('New McPerson')
      end
    end

    context 'invalid person' do
      it 'does not save the Person, logs a message, and adds record to ErrorReport' do
        event = create(:event)
        person = build(:person, firstname: 'New', lastname: 'McPerson', email: '')
        membership = build(:membership, event: event, person: person)

        lc = FakeLegacyConnector.new
        allow(lc).to receive(:get_members).with(event).and_return(lc.get_members_with_person(event: event, m: membership, lastname: 'McPerson'))
        expect(LegacyConnector).to receive(:new).and_return(lc)

        sync_errors = ErrorReport.new('SyncMembers', @event)
        expect(ErrorReport).to receive(:new).and_return(sync_errors)


        person.valid?
        expect(Rails.logger).to receive(:error).with("\n* Error saving #{event.code} person: #{person.name}, #{person.errors.full_messages}\n")
        expect(sync_errors).to receive(:add).twice.with(anything)
        SyncMembers.new(event)

        expect(Event.find(event.id).members.last).to be_nil
      end
    end
  end
end
