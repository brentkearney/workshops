# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe "SyncMembers" do
  before :each do
    Event.destroy_all
    Membership.destroy_all
    Person.destroy_all
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

        expect {
          expect{
            SyncMembers.new(new_event)
          }.to change { ActionMailer::Base.deliveries.count }.by(1)
        }.to raise_error('NoResultsError')
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
    def test_update(local_person:, fields:)
      event = create(:event)
      membership = create(:membership, event: event, person: local_person)
      lc = FakeLegacyConnector.new
      allow(lc).to receive(:get_members).with(event)
        .and_return(lc.get_members_with_person(e: event,
                                               m: membership,
                                               changed_fields: fields))
      expect(LegacyConnector).to receive(:new).and_return(lc)

      SyncMembers.new(event)

      lp = Person.find(local_person.id)

      fields.each_pair do |k, v|
        expect(lp.send(k)).to eq(v)
      end
    end

    context 'remote person with matching legacy_id' do
      it 'updates the local person with changed fields' do
        local_person = create(:person, lastname: 'Localperson', legacy_id: 666)
        updated_fields = { lastname: 'RemotePerson', address1: 'foo' }
        test_update(local_person: local_person, fields: updated_fields)
      end
    end

    context 'remote person without a legacy_id' do
      it 'finds local person based on email address, and updates' do
        local_person = create(:person, lastname: 'Localperson', legacy_id: nil)
        updated_fields = { lastname: 'RemotePerson' }
        test_update(local_person: local_person, fields: updated_fields)
      end
    end

    def setup_remote(event, membership, changed_fields)
      lc = FakeLegacyConnector.new
      remote_members = lc.get_members_with_person(
        e: event, m: membership, changed_fields: changed_fields
      )
      Rails.logger.debug "\n\n* FakeLegacyConnector returned remote_members: #{remote_members.inspect}\n\n"
      allow(lc).to receive(:get_members).with(event)
        .and_return(remote_members)
      expect(LegacyConnector).to receive(:new).and_return(lc)
    end

    context 'without a local person' do
      it 'creates a new person record' do
        event = create(:event)
        setup_remote(event, nil, lastname: 'Remoteperson')

        SyncMembers.new(event)

        lp = Event.find(event.id).members.last
        expect(lp.lastname).to eq('Remoteperson')
      end
    end

    context 'Email & legacy_id updates' do
      before do
        @event = create(:event)
      end

      context 'member of event has matching legacy_id but different email' do
        it "updates the member's email address" do
          member = create(:membership, event: @event)
          setup_remote(@event, member, email: 'new@email.com')

          SyncMembers.new(@event)

          expect(Membership.find(member.id).person.email).to eq('new@email.com')
        end
      end

      context 'member of another event has matching legacy_id but different email' do
        it 'adds that person to event, updates its email address' do
          person = create(:person, legacy_id: 12, email: 'no@bueno.mx')
          create(:membership, person: person)
          fields = { email: 'foo@bar.com', legacy_id: 12 }
          setup_remote(@event, nil, fields)

          SyncMembers.new(@event)

          expect(@event.members).to include(person)
          expect(Person.find(person.id).email).to eq('foo@bar.com')
        end
      end

      context 'member of event has different legacy_id but same email' do
        it 'updates legacy_id' do
          person = create(:person, legacy_id: 666)
          member = create(:membership, event: @event, person: person)
          email = person.email
          remote_fields = { email: email, legacy_id: 999 }
          setup_remote(@event, member, remote_fields)

          SyncMembers.new(@event)

          person = Person.find_by_email(email)
          expect(person.legacy_id).to eq(999)
          expect(@event.memberships).to include(person.memberships.last)
        end
      end

      context 'member of another event has different legacy_id, same email' do
        it 'adds person to event, updates its legacy_id' do
          person = create(:person, legacy_id: 666)
          create(:membership, person: person)
          remote_fields = { email: person.email, legacy_id: 999 }
          setup_remote(@event, nil, remote_fields)

          SyncMembers.new(@event)

          expect(@event.members).to include(person)
          expect(Person.find_by_email(person.email).legacy_id).to eq(999)
        end
      end

      context 'member of event does not match remote legacy_ids or emails' do
        it 'deletes that event membership' do
          @event.memberships.destroy_all
          member1 = create(:membership, event: @event)
          member2 = create(:membership, event: @event)
          setup_remote(@event, member2, firstname: 'Remotely')

          SyncMembers.new(@event)

          expect { Membership.find(member1.id) }
            .to raise_exception(ActiveRecord::RecordNotFound)
          expect(Membership.where(event: @event)).to include(member2)
        end
      end
    end
  end

  describe '.save_person' do
    context 'valid person' do
      it 'saves the Person and logs a message' do
        event = create(:event)
        person = build(:person, firstname: 'New', lastname: 'McPerson')
        membership = create(:membership, event: event, person: person)
        lc = FakeLegacyConnector.new
        fields = { lastname: 'McPerson' }
        allow(lc).to receive(:get_members).with(event)
          .and_return(lc.get_members_with_person(e: event,
                                                 m: membership,
                                                 changed_fields: fields))
        expect(LegacyConnector).to receive(:new).and_return(lc)

        expect(Rails.logger).to receive(:info).with("\n\n* Saved #{event.code} person: New McPerson\n")
        expect(Rails.logger).to receive(:info).with("\n\n* Saved #{event.code} membership for New McPerson\n")

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
        fields = { lastname: 'McPerson' }
        allow(lc).to receive(:get_members).with(event)
          .and_return(lc.get_members_with_person(e: event, m: membership,
                                                 changed_fields: fields))
        expect(LegacyConnector).to receive(:new).and_return(lc)

        sync_errors = ErrorReport.new('SyncMembers', @event)
        expect(ErrorReport).to receive(:new).and_return(sync_errors)


        person.valid?
        membership.valid?
        expect(Rails.logger).to receive(:error).with("\n\n* Error saving #{event.code} person: #{person.name}, #{person.errors.full_messages}\n")
        expect(Rails.logger).to receive(:error).with("\n\n* Error saving #{event.code} membership for #{membership.person.name}: #{membership.errors.full_messages}\n")
        expect(sync_errors).to receive(:add).twice.with(anything)
        SyncMembers.new(event)

        expect(Event.find(event.id).members.last).to be_nil
      end
    end
  end

  describe '.save_membership' do
    context 'valid membership' do
      it 'saves the Membership and logs a message' do
        event = create(:event)
        person = create(:person, lastname: 'Smith')
        membership = build(:membership, person: person, event: event,
                                        staff_notes: 'Hi there!')
        lc = FakeLegacyConnector.new
        fields = { lastname: 'Smith' }
        allow(lc).to receive(:get_members).with(event)
          .and_return(lc.get_members_with_person(e: event, m:
                                                 membership,
                                                 changed_fields: fields))
        expect(LegacyConnector).to receive(:new).and_return(lc)

        expect(Rails.logger).to receive(:info)
          .with("\n\n* Saved #{event.code} person: #{person.name}\n")
        expect(Rails.logger).to receive(:info)
          .with("\n\n* Saved #{event.code} membership for #{membership.person.name}\n")
        SyncMembers.new(event)

        lm = Event.find(event.id).memberships.last
        expect(lm.staff_notes).to eq('Hi there!')
      end
    end

    context 'invalid membership' do
      it 'does not save the Membership, logs a message,
        and adds record to ErrorReport' do
        event = create(:event)
        person = create(:person, lastname: 'Smith')
        membership = build(:membership, person: person,
                                        event: event,
                                        arrival_date: '1973-01-01')

        lc = FakeLegacyConnector.new
        fields = { lastname: 'Smith' }
        allow(lc).to receive(:get_members).with(event)
          .and_return(lc.get_members_with_person(e: event, m: membership,
                                                 changed_fields: fields))
        expect(LegacyConnector).to receive(:new).and_return(lc)

        sync_errors = ErrorReport.new('SyncMembers', event)
        expect(ErrorReport).to receive(:new).and_return(sync_errors)

        membership.valid?
        expect(Rails.logger).to receive(:error)
          .with("\n\n* Error saving #{event.code} membership for #{membership.person.name}: #{membership.errors.full_messages}\n")
        expect(sync_errors).to receive(:add).with(anything)
        SyncMembers.new(event)

        expect(Event.find(event.id).memberships.last).to be_nil
      end
    end
  end

  describe '.update_membership' do
    context 'without a local membership' do
      it 'creates a new membership' do
        event = create(:event)
        person = create(:person)
        lc = FakeLegacyConnector.new
        allow(lc).to receive(:get_members).with(event).and_return(lc.get_members_with_new_membership(e: event, p: person))
        expect(LegacyConnector).to receive(:new).and_return(lc)

        SyncMembers.new(event)

        expect(Event.find(event.id).members.last).to eq(person)
      end
    end

    context 'with a local membership' do
      it 'updates the local membership' do
        membership = create(:membership)
        lc = FakeLegacyConnector.new
        allow(lc).to receive(:get_members).with(membership.event).and_return(lc.get_members_with_changed_membership(m: membership, sn: 'Hi'))
        expect(LegacyConnector).to receive(:new).and_return(lc)

        SyncMembers.new(membership.event)

        expect(Event.find(membership.event.id).memberships.last.staff_notes).to eq('Hi')
      end
    end
  end

  describe '.prune_members' do
    before do
      @event = create(:event_with_members)
      allow(LegacyConnector).to receive(:new).and_return(FakeLegacyConnector.new)
      @sm = SyncMembers.new(@event)
    end

    it 'removes local members that are not in remote memberships' do
      new_member = create(:membership, event: @event)
      @sm.prune_members

      expect(Event.find(@event.id).memberships).not_to include(new_member)
    end
  end
end
