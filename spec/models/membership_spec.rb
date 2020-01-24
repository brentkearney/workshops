# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe 'Model validations: Membership', type: :model do
  before do
    @event = create(:event, current: true)
    @person = create(:person)
    @membership = create(:membership, person: @person, event: @event)
    om = create(:membership, event: @event, role: 'Contact Organizer')
    @organizer = om.person
  end

  it 'has valid factory' do
    expect(@membership).to be_valid
  end

  it 'is invalid without an event association' do
    @membership.event = nil
    expect(@membership.valid?).to be_falsey
    expect(@membership.errors.key?(:event)).to be_truthy
  end

  it 'is invalid without a person association' do
    @membership.person_id = nil
    expect(@membership.valid?).to be_falsey
    expect(@membership.errors.key?(:person)).to be_truthy
  end

  it 'is invalid without unique people per event' do
    new_membership = build(:membership, person: @person, event: @event)

    expect(new_membership.valid?).to be_falsey
    expect(new_membership.errors.key?(:person)).to be_truthy
  end

  it 'is invalid if arrival dates are after the event ends' do
    @membership.arrival_date = @event.end_date + 2.days
    @membership.valid?
    expect(@membership.errors.key?(:arrival_date)).to be_truthy
  end

  it 'is invalid if departure dates are before the event begins' do
    @membership.departure_date = @event.start_date - 2.days
    @membership.valid?
    expect(@membership.errors.key?(:departure_date)).to be_truthy
  end

  it 'is invalid if arrival dates are a month before the event begins' do
    @membership.arrival_date = @event.start_date - 31.days
    @membership.valid?
    expect(@membership.errors.key?(:arrival_date)).to be_truthy
  end

  it 'is valid if arrival dates are within the period of the event' do
    @membership.arrival_date = @event.start_date + 1.days
    expect(@membership.valid?).to be_truthy
  end

  it 'is valid if departure dates are within the period of the event' do
    @membership.departure_date = @event.end_date - 1.days
    expect(@membership.valid?).to be_truthy
  end

  it 'is invalid if arrival is before event start' do
    @membership.arrival_date = @event.start_date - 1.days
    expect(@membership.valid?).to be_falsey
  end

  it '  ...but early arrivals can be set by staff' do
    @membership.update_by_staff = true
    @membership.arrival_date = @event.start_date - 1.days
    expect(@membership.valid?).to be_truthy
  end

  it 'is invalid if departure is after event end' do
    @membership.departure_date = @event.end_date + 1.days
    expect(@membership.valid?).to be_falsey
  end

  it '  ...but late departures can be set by staff' do
    @membership.update_by_staff = true
    @membership.departure_date = @event.end_date + 1.days
    expect(@membership.valid?).to be_truthy
  end

  it 'arrival and departure validations skipped if attendance is Declined' do
    @membership.update_by_staff = false
    @membership.arrival_date = @event.start_date - 1.days
    @membership.departure_date = @event.end_date + 1.days
    @membership.attendance = 'Declined'
    expect(@membership.valid?).to be_truthy
  end

  it 'is valid with nil arrival and departure dates' do
    @membership.arrival_date = nil
    expect(@membership.valid?).to be_truthy

    @membership.departure_date = nil
    expect(@membership.valid?).to be_truthy
  end

  it 'is invalid if the number of invited + confirmed participants is greater
    than max_participants' do
    @event.max_participants = @event.num_participants + 1
    @event.save

    second_membership = create(:membership, event: @event,
                                            attendance: 'Invited')
    expect(second_membership).to be_valid

    third_membership = create(:membership, event: @event, attendance: 'Invited')
    expect(third_membership).not_to be_valid
  end

  it 'does not count Observers as part of the confirmed number of
    participants' do
    @event.max_participants = @event.num_participants
    @event.save

    observer_membership = create(:membership, event: @event,
                                  attendance: 'Invited', role: 'Observer')
    expect(observer_membership).to be_valid
  end

  it 'is invalid if the number of invited + confirmed observers is greater
    than max_observers' do
    observers = @event.memberships.where(role: 'Observer')
                                 .where.not(attendance: 'Declined')
                                 .where.not(attendance: 'Not Yet Invited').count

    @event.max_observers = observers + 1
    @event.save

    new_observer = create(:membership, event: @event,
                                  attendance: 'Invited', role: 'Observer')
    expect(new_observer).to be_valid

    new_observer2 = create(:membership, event: @event,
                                   attendance: 'Invited', role: 'Observer')
    expect(new_observer2).not_to be_valid
  end

  it 'sets a role, if absent' do
    @membership.role = nil
    @membership.save
    expect(@membership.role).to eq('Participant')
  end

  it 'sets an attendance, if absent' do
    @membership.attendance = nil
    @membership.save
    expect(@membership.attendance).to eq('Not Yet Invited')
  end

  it "sets billing to US billing code, if member's country is USA" do
    @membership.billing = nil
    @membership.person.country = 'United States'
    @membership.save

    expect(@membership.billing).to eq('EO2')
  end

  it "sets billing to default billing code, if member's country is not USA" do
    @membership.billing = nil
    @membership.person.country = 'France'
    @membership.save

    expect(@membership.billing).to eq('EO1')
  end

  it 'sets num_guests if empty but has_guest selected' do
    @membership.has_guest = true
    @membership.num_guests = 0
    @membership.save
    expect(@membership.num_guests).to eq(1)
  end

  it 'sets has_guests if false but num_guests > 0' do
    @membership.has_guest = false
    @membership.num_guests = 2
    @membership.save
    expect(@membership.has_guest).to eq(true)
  end

  it "increases associated event's confirmed_cache when Confirmed member is
    added" do
    counter_cache = @event.confirmed_count
    create(:membership, event: @event, role: 'Confirmed')

    expect(@event.confirmed_count).to eq(counter_cache + 1)
  end

  it "decreases associated event's confirmed_cache when Confirmed member is
    deleted" do
    create(:membership, event: @event, role: 'Confirmed')
    counter_cache = @event.confirmed_count

    @event.memberships.last.destroy

    expect(@event.confirmed_count).to eq(counter_cache - 1)
  end

  context 'Email notifications upon updated fields' do

    def expect_confirmation_notice(job_type)
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).not_to eq 0
      jobs = []
      ActiveJob::Base.queue_adapter.enqueued_jobs.each do |job|
        jobs << job[:job].to_s
      end

      expect(jobs).to include(job_type)
    end

    before do
      @event.start_date = Date.current + 1.month
      @event.end_date = @event.start_date + 5.days
      @event.save
      @membership.attendance = 'Confirmed'
      @membership.has_guest = false
      @membership.update_by_staff = false
      @membership.own_accommodation = false
      @membership.special_info = 'None.'
      @membership.updated_by = @membership.person.name
      @membership.save
    end

    it 'notifies staff if attendance changes to or from confirmed' do
      @membership.attendance = 'Not Yet Invited'
      @membership.save
      expect_confirmation_notice('EmailStaffConfirmationNoticeJob')
    end

    it 'notifies organizer if attendance changes' do
      @membership.attendance = 'Declined'
      @membership.save
      expect_confirmation_notice('EmailOrganizerNoticeJob')
    end

    it 'notifies staff if has_guest is changed' do
      @membership.has_guest = true
      @membership.save
      expect_confirmation_notice('EmailStaffConfirmationNoticeJob')
    end

    it 'notifies staff if own_accommodation is changed' do
      @membership.own_accommodation = true
      @membership.save
      expect_confirmation_notice('EmailStaffConfirmationNoticeJob')
    end

    it 'notifies staff if special_info is changed' do
      @membership.special_info = 'I only eat meat.'
      @membership.save
      expect_confirmation_notice('EmailStaffConfirmationNoticeJob')
    end
  end

  it 'includes changed fields & updated_by in change notice' do
    @event.start_date = Date.current + 1.month
    @event.end_date = @event.start_date + 5.days
    @event.save
    @membership.attendance = 'Confirmed'
    @membership.updated_by = 'Workshops importer'
    @membership.save

    @membership.attendance = 'Declined'
    @membership.updated_by = @membership.person.name
    @membership.save

    msg = ActiveJob::Base.queue_adapter.enqueued_jobs.first[:args].second

    expect(msg.values.first).to eq(['Attendance was "Confirmed" and is now "Declined".'])
    expect(msg.values.second).to eq(@membership.person.name)
  end

  it 'skips attendance notification if .changed_fields? is untrue' do
    allow_any_instance_of(MembershipChangeNotice).to receive(:changed_fields?)
      .and_return(false)
    expect(@membership.special_info).not_to eq('ABC')
    @membership.special_info = 'ABC'
    @membership.save

    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq 0
  end

  it 'sends staff notice if event date is inside "confirmation_lead" time' do
    lead_time = GetSetting.confirmation_lead_time(@event.location)

    new_start = Date.current + lead_time - 1.day
    @event.start_date = new_start
    @event.end_date = new_start + 5.days
    @event.save

    expect(@membership.special_info).not_to eq('DEF')
    @membership.special_info = 'DEF'
    @membership.updated_by = @membership.person.name
    @membership.save

    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq 2
    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.last[:args].last)
      .to eq('confirmation_notices')
  end

  it 'skips staff notice if event date is outside "confirmation_lead" time,
    but still sends notice to program_coordinator' do
    lead_time = GetSetting.confirmation_lead_time(@event.location)

    new_start = Date.current + lead_time + 1.week
    @event.start_date = new_start
    @event.end_date = new_start + 5.days
    @event.save

    expect(@membership.special_info).not_to eq('GHI')
    @membership.special_info = 'GHI'
    @membership.updated_by = @membership.person.name
    @membership.save

    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq 1
    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.last[:args].last)
      .to eq('program_coordinator')
  end

  it 'skips staff notice to program_coordinator if updated_by is not member' do
    lead_time = GetSetting.confirmation_lead_time(@event.location)

    new_start = Date.current + lead_time + 1.week
    @event.start_date = new_start
    @event.end_date = new_start + 5.days
    @event.save

    expect(@membership.special_info).not_to eq('JKL')
    @membership.special_info = 'JKL'
    @membership.updated_by = 'Workshops importer'
    @membership.save

    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq 0
  end

  it 'skips notification if event date is in the past' do
    new_start = Date.current - 2.weeks
    @event.start_date = new_start
    @event.end_date = new_start + 5.days
    @event.save

    expect(@membership.special_info).not_to eq('MNO')
    @membership.special_info = 'MNO'
    @membership.save

    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq 0
  end

  it 'syncs with legacy db if update_remote flag is set' do
    allow(SyncMembershipJob).to receive(:perform_later)
    @membership.attendance = 'Confirmed'
    @membership.save

    @membership.update_remote = true
    @membership.attendance = 'Declined'
    @membership.save

    expect(SyncMembershipJob).to have_received(:perform_later)
  end

  it '.arrives returns "Not set" or formatted date' do
    @membership.arrival_date = nil
    @membership.save
    expect(@membership.arrives).to eq('Not set')

    date = @membership.event.start_date + 1.day
    @membership.arrival_date = date
    @membership.save
    expect(@membership.arrives).to eq(date.strftime('%b %-d, %Y'))
  end

  it '.departs returns "Not set" or formatted date' do
    @membership.departure_date = nil
    @membership.save
    expect(@membership.departs).to eq('Not set')

    date = @membership.event.end_date - 1.day
    @membership.departure_date = date
    @membership.save
    expect(@membership.departs).to eq(date.strftime('%b %-d, %Y'))
  end

  it '.rsvp_date returns "N/A" or formatted date' do
    @membership.replied_at = nil
    @membership.save
    expect(@membership.rsvp_date).to eq('N/A')

    rsvp_time = DateTime.yesterday.midday
    @membership.replied_at = rsvp_time
    @membership.save

    formatted = rsvp_time.in_time_zone(@membership.event.time_zone)
                         .strftime('%b %-d, %Y %H:%M %Z')
    expect(@membership.rsvp_date).to eq(formatted)
  end

  it '.shares_email? indicates email sharing preference' do
    @membership.share_email = true
    @membership.save
    expect(@membership.shares_email?).to be_truthy

    @membership.share_email = false
    @membership.save
    expect(@membership.shares_email?).to be_falsey
  end

  it '.organizer? tests if member is organizer' do
    @membership.role = 'Participant'
    @membership.save
    expect(@membership.organizer?).to be_falsey

    @membership.role = 'Organizer'
    @membership.save
    expect(@membership.organizer?).to be_truthy
  end
end
