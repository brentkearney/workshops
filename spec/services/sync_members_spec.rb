# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe "SyncMembers" do
  before do
    @event = create(:event)
    @eventm = create(:event_with_members)
  end

  def reset_dates
    @eventm.memberships.each do |m|
      m.updated_at = DateTime.parse('1970-01-01 00:00:00')
      m.person.updated_at = DateTime.parse('1970-01-01 00:00:00')
      m.save
    end
  end

  it '.initialize' do
    expect(LegacyConnector).to receive(:new).and_return(FakeLegacyConnector.new)

    sm = SyncMembers.new(@eventm)

    expect(sm.event).to eq(@eventm)
    expect(sm.remote_members).not_to be_empty
    expect(sm.local_members).not_to be_empty
    expect(sm.sync_errors).to be_a(ErrorReport)
  end

  describe '.recently_synced?' do
    before do
      lc = FakeLegacyConnector.new
      allow(lc).to receive(:get_members).with(@eventm).and_return(lc.get_members_with_changed_fields(@eventm))
      expect(LegacyConnector).to receive(:new).and_return(lc)
      reset_dates
    end

    it 'returns false if event.sync_time is empty' do
      sm = SyncMembers.new(@eventm)
      @eventm.sync_time = nil
      @eventm.save

      expect(sm.recently_synced?).to be_falsey
    end

    it 'returns false if event.sync_time is greater than 5 minutes from now' do
      sm = SyncMembers.new(@eventm)
      @eventm.sync_time = DateTime.now - 10.minutes
      @eventm.save

      expect(sm.recently_synced?).to be_falsey
    end

    it 'returns true if event.sync_time is less than 5 minutes from now' do
      sm = SyncMembers.new(@eventm)
      @eventm.sync_time = DateTime.now - 4.minutes
      @eventm.save

      expect(sm.recently_synced?).to be_truthy
    end
  end

  describe '.set_sync_time' do
    before do
      lc = FakeLegacyConnector.new
      allow(lc).to receive(:get_members).with(@eventm).and_return(lc.get_members_with_changed_fields(@eventm))
      expect(LegacyConnector).to receive(:new).and_return(lc)
    end

    it 'adds the current time to the event.sync_time field' do
      @eventm.sync_time = nil
      @eventm.save

      SyncMembers.new(@eventm)
      evnt = Event.find(@eventm.id)
      expect(evnt.sync_time).not_to be_blank
      expect(evnt.sync_time).to be_a(ActiveSupport::TimeWithZone)
    end
  end

  describe '.get_remote_members' do
    context 'with no remote members' do
      it 'sends a message to ErrorReport and raises an error message' do
        lc = FakeLegacyConnector.new
        expect(LegacyConnector).to receive(:new).and_return(lc)

        expect_any_instance_of(ErrorReport).to receive(:add).with(lc, "Unable to retrieve any remote members for #{@event.code}")
        expect { @sm = SyncMembers.new(@event) }.to raise_error('NoResultsError')
      end

      it 'sends email to staff' do
        lc = FakeLegacyConnector.new
        expect(LegacyConnector).to receive(:new).and_return(lc)

        expect {
          expect{
            SyncMembers.new(@event)
          }.to change { ActionMailer::Base.deliveries.count }.by(1)
        }.to raise_error('NoResultsError')
      end
    end

    context 'with remote members' do
      it 'returns the remote members' do
        lc = FakeLegacyConnector.new
        expect(LegacyConnector).to receive(:new).and_return(lc)

        sm = SyncMembers.new(@eventm)

        expect(sm.remote_members).not_to be_empty
      end
    end
  end

  describe '.fix_remote_fields' do
    before do
      lc = FakeLegacyConnector.new
      # get_members_with_changed_fields() sets nil fields and messes up email
      allow(lc).to receive(:get_members).with(@eventm).and_return(lc.get_members_with_changed_fields(@eventm))
      expect(LegacyConnector).to receive(:new).and_return(lc)
      reset_dates
    end

    it 'fills in blank fields, sets Backup Participant attendance to "Not Yet Invited"' do
      SyncMembers.new(@eventm)
      member = Event.find(@eventm.id).memberships.last

      expect(member.person.updated_by).to eq('FactoryBot')
      expect(member.person.updated_at).not_to be_nil
      expect(member.updated_by).to eq('Workshops importer')
      expect(member.updated_at).not_to be_nil
      expect(member.replied_at).to be_nil
      expect(member.role).to eq('Backup Participant')
      expect(member.attendance).to eq('Not Yet Invited')
    end

    it 'downcases and strips whitespace from emails' do
      before_email = Event.find(@eventm.id).memberships.first.person.email
      SyncMembers.new(@eventm)
      after_email =  Event.find(@eventm.id).memberships.first.person.email
      expect(after_email).to eq(before_email)
    end
  end

  describe '.update_person' do
    before do
      reset_dates
    end

    def test_update(local_person:, fields:)
      updated = DateTime.parse('1970-01-01 00:00:00')
      membership = create(:membership, event: @eventm, person: local_person,
        updated_at: updated)
      lc = FakeLegacyConnector.new
      allow(lc).to receive(:get_members).with(@eventm)
        .and_return(lc.get_members_with_person(e: @eventm,
                                               m: membership,
                                               changed_fields: fields))
      expect(LegacyConnector).to receive(:new).and_return(lc)

      SyncMembers.new(@eventm)

      lp = Person.find(local_person.id)

      fields.each_pair do |k, v|
        expect(lp.send(k)).to eq(v)
      end
    end

    def setup_remote(event, membership, changed_fields)
      lc = FakeLegacyConnector.new
      membership ||= create(:membership, event: event)

      remote_members = lc.get_members_with_person(
        e: event, m: membership, changed_fields: changed_fields
      )
      allow(lc).to receive(:get_members).with(event)
        .and_return(remote_members)
      expect(LegacyConnector).to receive(:new).and_return(lc)
    end

    context 'remote person with matching legacy_id' do
      it 'updates the local person with changed fields' do
        updated = DateTime.parse('1970-01-01 00:00:00')
        local_person = create(:person, lastname: 'Localperson', legacy_id: 666,
          updated_at: updated)
        updated_fields = { lastname: 'RemotePerson', address1: 'foo' }
        test_update(local_person: local_person, fields: updated_fields)
      end
    end

    context 'remote person without a legacy_id' do
      it 'finds local person based on email address, and updates' do
        updated = DateTime.parse('1970-01-01 00:00:00')
        local_person = create(:person, lastname: 'Localperson', legacy_id: nil,
            updated_at: updated)
        updated_fields = { lastname: 'RemotePerson' }
        test_update(local_person: local_person, fields: updated_fields)
      end
    end

    context 'without a local person' do
      it 'creates a new person record' do
        remote_fields = { lastname: 'RemotePerson', email: 'new@member.net',
                           legacy_id: 1234 }
        setup_remote(@eventm, nil, remote_fields)

        SyncMembers.new(@eventm)

        person = Person.find_by_email('new@member.net')
        expect(person.events).to include(@eventm)
      end
    end

    context 'Email & legacy_id updates' do
      context 'matching legacy_ids, but different emails' do
        before do
          updated = DateTime.parse('1970-01-01 00:00:00')
          @person1 = create(:person, email: 'sam@jones.net', legacy_id: 111,
            updated_at: updated)
          @membership1 = create(:membership, person: @person1, event: @eventm,
            updated_at: updated)

          @person2 = create(:person, email: 'fred@smith.com', legacy_id: 222,
            updated_at: updated)
          @membership2 = create(:membership, person: @person2, event: @event,
            updated_at: updated)

          @lecture = create(:lecture, person: @person2, event: @eventm)
          create(:user, person: @person2, email: @person2.email)

          remote_fields = { email: 'fred@smith.com', legacy_id: 111 }
          setup_remote(@eventm, @membership1, remote_fields)
          SyncMembers.new(@eventm)
        end

        after do
          @event.memberships.destroy_all
        end

        it 'chooses the person record with the most data' do
          membership = Membership.find(@membership1.id)
          expect(membership.person_id).to eq(@person2.id)
        end

        it 'consolidates event memberships into one person record' do
          expect { Person.find(@person1.id) }
            .to raise_exception(ActiveRecord::RecordNotFound)
          updated_person = Person.find(@person2.id)
          events = updated_person.memberships.collect(&:event).flatten
          expect(events).to match_array([@event, @eventm])
          expect(updated_person.legacy_id).to eq(222)
        end

        it 'consolidates lectures into one person record' do
          lecture = Lecture.find(@lecture.id)
          expect(lecture.person).to eq(@person2)
        end

        it 'moves user account to updated person record' do
          expect(User.where(person_id: @person2.id)).not_to be_nil
        end
      end

      context 'matching emails, but different legacy_ids' do
        before do
          updated = DateTime.parse('1970-01-01 00:00:00')
          @person1 = create(:person, email: 'sam@jones.net', legacy_id: 111,
            updated_at: updated)
          @membership1 = create(:membership, person: @person1, event: @eventm,
            updated_at: updated)

          @person2 = create(:person, email: 'fred@smith.com', legacy_id: 222,
            updated_at: updated)
          @membership2 = create(:membership, person: @person2, event: @event,
            updated_at: updated)

          @lecture = create(:lecture, person: @person2, event: @event)
          @puser = create(:user, person: @person1, email: @person1.email)

          remote_fields = { email: 'sam@jones.net', legacy_id: 222, fax: 1234 }
          setup_remote(@eventm, @membership1, remote_fields)
        end

        after do
          @event.memberships.destroy_all
        end

        it 'adds local record to the event' do
          SyncMembers.new(@eventm)
          members = Event.find(@eventm.id).members
          expect(members).to include(@person1)
          expect(members).not_to include(@person2)
        end

        it 'updates legacy_db to fix duplicates' do
          allow(ReplacePersonJob).to receive(:perform_later)
          SyncMembers.new(@eventm)
          expect(ReplacePersonJob).to have_received(:perform_later).with(222, 111)
        end

        it 'if already a member of the event, does not produce error' do
          sync_errors = spy('sync_errors')
          allow(ErrorReport).to receive(:new).and_return(sync_errors)

          SyncMembers.new(@eventm)

          expect(sync_errors).not_to have_received(:add)
        end

        it 'transfers lectures' do
          SyncMembers.new(@eventm)
          expect(Lecture.find(@lecture.id).person_id).to eq(@person1.id)
        end

        it 'updates local record with remote information' do
          SyncMembers.new(@eventm)
          expect(Person.find(@person1.id).fax).to eq('1234')
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

    context 'invited_by & invited_on updates' do
      it 'updates invited_by & invited_on if remote is more recent' do
        updated = DateTime.parse('1970-01-01 00:00:00')
        membership = create(:membership, invited_by: 'User 1',
          invited_on: 1.week.ago, updated_at: updated)
        more_recent = DateTime.now.in_time_zone(membership.event.time_zone)
        remote_fields = { membership: { invited_by: 'User 2', invited_on: more_recent } }
        setup_remote(membership.event, membership, remote_fields)
        SyncMembers.new(membership.event)

        updated = Membership.find(membership.id)
        expect(updated.invited_on.to_i).to eq(more_recent.to_i)
        expect(updated.invited_by).to eq('User 2')
      end

      it 'does not update invited_by & invited_on if remote is less recent' do
        recent = 1.day.ago
        membership = create(:membership, invited_by: 'User 1', invited_on: recent)
        less_recent = 3.days.ago
        remote_fields = { membership: { invited_by: 'User 2', invited_on: less_recent } }
        setup_remote(membership.event, membership, remote_fields)
        SyncMembers.new(membership.event)

        updated = Membership.find(membership.id)
        expect(updated.invited_on.to_i).to eq(recent.to_i)
        expect(updated.invited_by).to eq('User 1')
      end
    end
  end


  describe '.save_person' do
    before do
      reset_dates
    end

    context 'valid person' do
      it 'saves the Person and logs a message' do
        lc = FakeLegacyConnector.new
        fields = { firstname: 'New', lastname: 'McPerson' }
        allow(lc).to receive(:get_members).with(@eventm)
          .and_return(lc.get_members_with_person(e: @eventm,
                                                 m: nil,
                                                 changed_fields: fields))
        expect(LegacyConnector).to receive(:new).and_return(lc)

        expect(Rails.logger).to receive(:info).with("\n\n" + "* Saved
          #{@eventm.code} person: New McPerson".squish + "\n")
        expect(Rails.logger).to receive(:info).with("\n\n" + "* Saved
          #{@eventm.code} membership for New McPerson".squish + "\n")

        SyncMembers.new(@eventm)

        lp = Event.find(@eventm.id).members.last
        expect(lp.name).to eq('New McPerson')
      end
    end

    context 'invalid person' do
      it 'does not save the Person, logs a message, and adds record to ErrorReport' do
        lc = FakeLegacyConnector.new
        fields = { firstname: 'New', lastname: 'McPerson', email: '' }
        allow(lc).to receive(:get_members).with(@event)
          .and_return(lc.get_members_with_person(e: @event, m: nil,
                                                 changed_fields: fields))
        expect(LegacyConnector).to receive(:new).and_return(lc)

        sync_errors = ErrorReport.new('SyncMembers', @event)
        expect(ErrorReport).to receive(:new).and_return(sync_errors)

        person = build(:person, email: '')
        person.valid?

        expect(Rails.logger).to receive(:error).with("\n\n" + "* Error saving
          #{@event.code} person: New McPerson,
          #{person.errors.full_messages}".squish + "\n")
        expect(sync_errors).to receive(:add).once.with(anything)
        SyncMembers.new(@event)

        expect(Event.find(@event.id).members.last).to be_nil
        @event.memberships.destroy_all
      end
    end
  end

  describe '.save_membership' do
    context 'valid membership' do
      before do
        updated = DateTime.parse('1970-01-01 00:00:00')
        @person = create(:person, lastname: 'Smith', updated_at: updated)
        @membership = build(:membership, person: @person, event: @event,
                                  staff_notes: 'Hi there!', updated_at: updated)
        @lc = FakeLegacyConnector.new
      end

      it 'saves the Membership and logs a message' do
        fields = { lastname: 'Smith' }
        allow(@lc).to receive(:get_members).with(@event)
          .and_return(@lc.get_members_with_person(e: @event, m:
                                                 @membership,
                                                 changed_fields: fields))
        expect(LegacyConnector).to receive(:new).and_return(@lc)

        expect(Rails.logger).to receive(:info)
          .with("\n\n* Saved #{@event.code} person: #{@person.name}\n")
        expect(Rails.logger).to receive(:info)
          .with("\n\n* Saved #{@event.code} membership for #{@membership.person.name}\n")
        SyncMembers.new(@event)

        lm = Event.find(@event.id).memberships.last
        expect(lm.staff_notes).to eq('Hi there!')
      end

      it 'accepts arrival & depature dates outside of event dates' do
        arrival = @event.start_date - 2.days
        @membership.arrival_date = arrival
        departure = @event.end_date + 2.days
        @membership.departure_date = departure

        fields = { lastname: 'Claus' }
        allow(@lc).to receive(:get_members).with(@event)
          .and_return(@lc.get_members_with_person(e: @event, m:
                                                 @membership,
                                                 changed_fields: fields))
        expect(LegacyConnector).to receive(:new).and_return(@lc)

        SyncMembers.new(@event)

        saved_member = Event.find(@event.id).memberships.last
        expect(saved_member).not_to be_nil
        expect(saved_member.arrival_date).to eq(arrival)
        expect(saved_member.departure_date).to eq(departure)
      end
    end

    context 'invalid membership' do
      it 'does not save the Membership, logs a message,
        and adds record to ErrorReport' do
        person = create(:person, lastname: 'Smith')
        membership = build(:membership, person: person,
                                        event: @event,
                                        arrival_date: '1973-01-01')

        lc = FakeLegacyConnector.new
        fields = { lastname: 'Smith' }
        allow(lc).to receive(:get_members).with(@event)
          .and_return(lc.get_members_with_person(e: @event, m: membership,
                                                 changed_fields: fields))
        expect(LegacyConnector).to receive(:new).and_return(lc)

        sync_errors = ErrorReport.new('SyncMembers', @event)
        expect(ErrorReport).to receive(:new).and_return(sync_errors)

        membership.valid?
        expect(Rails.logger).to receive(:error)
        expect(sync_errors).to receive(:add).with(anything)
        SyncMembers.new(@event)

        expect(Event.find(@event.id).memberships.last).to be_nil
      end
    end
  end

  describe '.update_membership' do
    context 'without a local membership' do
      it 'creates a new membership' do
        person = create(:person, updated_at: DateTime.parse('1970-01-01 00:00:00'))
        lc = FakeLegacyConnector.new
        allow(lc).to receive(:get_members).with(@event).and_return(lc.get_members_with_new_membership(e: @event, p: person))
        expect(LegacyConnector).to receive(:new).and_return(lc)

        SyncMembers.new(@event)

        expect(Event.find(@event.id).members.last).to eq(person)
        @event.memberships.destroy_all
      end
    end

    context 'with a local membership' do
      it 'updates the local membership' do
        reset_dates
        membership = @eventm.memberships.last
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
      allow(LegacyConnector).to receive(:new).and_return(FakeLegacyConnector.new)
      @sm = SyncMembers.new(@eventm)
    end

    it 'removes local members that are not in remote memberships' do
      new_member = create(:membership, event: @eventm)
      @sm.prune_members

      expect(Event.find(@eventm.id).memberships).not_to include(new_member)
    end

    it 'removes associated Invitations' do
      new_member = create(:membership, event: @eventm)
      invite = create(:invitation, membership: new_member)

      @sm.prune_members
      expect(Invitation.find_by_id(invite.id)).to be_nil
    end
  end

  describe '.check_max_participants' do
    before do
      Person.destroy_all
    end

    it 'checks whether the event has too many participants, sends report' do
      lc = FakeLegacyConnector.new
      allow(lc).to receive(:get_members).with(@event)
        .and_return(lc.exceed_max_participants(@event, 5))
      expect(LegacyConnector).to receive(:new).and_return(lc)

      sync_errors = ErrorReport.new('SyncMembers', @event)
      expect(ErrorReport).to receive(:new).and_return(sync_errors)

      # from sync_members.rb:100
      total_invited = @event.max_participants + 5
      msg = "Membership Totals:\n"
      msg += "Confirmed participants: #{total_invited}\n"
      msg += "Invited participants: 0\n"
      msg += "Undecided participants: 0\n"
      msg += "Not Yet Invited participants: 0\n"
      msg += "Declined participants: 0\n\n"
      msg += "Total invited participants: #{total_invited}\n"
      msg += "Total observers: 0\n"
      msg += "#{@event.code} Maximum allowed: #{@event.max_participants}\n"
      message = "#{@event.code} is overbooked!\n\n#{msg}"

      expect(sync_errors).to receive(:add).with(@event, message)
      expect(sync_errors).to receive(:send_report)
      SyncMembers.new(@event)
    end
  end
end
