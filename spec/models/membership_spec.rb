# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe 'Model validations: Membership', type: :model do

  before do
    @event = create(:event, code: '16w5666')
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
    expect(@membership.errors.has_key?(:event)).to be_truthy
  end

  it 'is invalid without a person association' do
    @membership.person_id = nil
    expect(@membership.valid?).to be_falsey
    expect(@membership.errors.has_key?(:person)).to be_truthy
  end

  it 'is invalid without unique people per event' do
    new_membership = build(:membership, person: @person, event: @event)

    expect(new_membership.valid?).to be_falsey
    expect(new_membership.errors.has_key?(:person)).to be_truthy
  end

  it 'is invalid if arrival dates are after the event ends' do
    @membership.arrival_date = @event.end_date + 2.days
    @membership.valid?
    expect(@membership.errors.has_key?(:arrival_date)).to be_truthy
  end

  it 'is invalid if departure dates are before the event begins' do
    @membership.departure_date = @event.start_date - 2.days
    @membership.valid?
    expect(@membership.errors.has_key?(:departure_date)).to be_truthy
  end

  it 'is invalid if arrival dates are a month before the event begins' do
    @membership.arrival_date = @event.start_date - 31.days
    @membership.valid?
    expect(@membership.errors.has_key?(:arrival_date)).to be_truthy
  end

  it 'is valid if arrival dates are within the period of the event' do
    @membership.arrival_date = @event.start_date + 1.days
    expect(@membership.valid?).to be_truthy
  end

  it 'is valid if departure dates are within the period of the event' do
    @membership.departure_date = @event.end_date - 1.days
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

  it 'sets a role automatically, if absent' do
    @membership.role = nil
    @membership.save
    expect(@membership.role).not_to be_nil
  end

  it 'sets an attendance automatically, if absent' do
    @membership.attendance = nil
    @membership.save
    expect(@membership.attendance).not_to be_nil
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

  it 'notifies staff if attendance changes to or from confirmed' do
    allow(EmailStaffConfirmationNoticeJob).to receive(:perform_later)
    expect(@membership.attendance).to eq('Confirmed')
    @membership.attendance = 'Not Yet Invited'
    @membership.save

    expect(EmailStaffConfirmationNoticeJob).to have_received(:perform_later)
  end

  it 'syncs with legacy db if sync_remote flag is set' do
    allow(SyncMembershipJob).to receive(:perform_later)
    @membership.attendance = 'Confirmed'
    @membership.save

    @membership.sync_remote = true
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
end
