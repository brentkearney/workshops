# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe 'Model validations: Membership', type: :model do

  before do
    @event = FactoryGirl.create(:event, code: '16w5666')
    @person = FactoryGirl.create(:person)
    @membership = FactoryGirl.create(:membership, person: @person, event: @event)
  end

  it 'has valid factory' do
    expect(FactoryGirl.create(:membership)).to be_valid
    expect(@membership).to be_valid
  end

  it 'is invalid without an event association' do
    expect(@membership.event).to be(@event)

    @membership.event = nil
    expect(@membership.valid?).to be_falsey
    expect(@membership.errors[:event].any?).to be_truthy
  end

  it 'is invalid without a person association' do
    expect(@membership.person).to be(@person)

    @membership.person_id = nil
    expect(@membership.valid?).to be_falsey
    expect(@membership.errors[:person].any?).to be_truthy
  end

  it 'is invalid without unique people per event' do
    expect(@membership.valid?).to be_truthy
    new_membership = FactoryGirl.build(:membership, person: @person, event: @event)

    expect(new_membership.valid?).to be_falsey
    expect(new_membership.errors[:person].any?).to be_truthy
  end

  it 'is invalid if arrival dates are after the event ends' do
    @membership.arrival_date = @event.end_date + 2.days
    @membership.valid?
    expect(@membership.errors[:arrival_date].any?).to be_truthy
  end

  it 'is invalid if departure dates are before the event begins' do
    @membership.departure_date = @event.start_date - 2.days
    @membership.valid?
    expect(@membership.errors[:departure_date].any?).to be_truthy
  end

  it 'is invalid if arrival dates are a month before the event begins' do
    @membership.arrival_date = @event.start_date - 31.days
    @membership.valid?
    expect(@membership.errors[:arrival_date].any?).to be_truthy
  end

  it 'is valid if arrival dates are within the period of the event' do
    fresh_event = FactoryGirl.create(:event)
    fresh_membership = FactoryGirl.create(:membership, event: fresh_event)
    fresh_membership.arrival_date = fresh_event.start_date + 1.days
    expect(fresh_membership.valid?).to be_truthy
  end

  it 'is valid if departure dates are within the period of the event' do
    fresh_event = FactoryGirl.create(:event)
    fresh_membership = FactoryGirl.create(:membership, event: fresh_event)
    fresh_membership.departure_date = fresh_event.end_date - 1.days
    fresh_membership.valid?
    expect(fresh_membership.valid?).to be_truthy
  end

  it 'is valid with nil arrival and departure dates' do
    @membership.arrival_date = nil
    expect(@membership.valid?).to be_truthy

    @membership.departure_date = nil
    expect(@membership.valid?).to be_truthy
  end

  it 'is invalid if the number of invited + confirmed participants is greater than max_participants' do
    @event.max_participants = @event.num_participants + 1
    @event.save

    second_membership = FactoryGirl.create(:membership, event: @event, attendance: 'Invited')
    expect(second_membership).to be_valid

    third_membership = FactoryGirl.create(:membership, event: @event, attendance: 'Invited')
    expect(third_membership).not_to be_valid
  end

  it 'does not count Observers as part of the confirmed number of participants' do
    @event.max_participants = @event.num_participants
    @event.save

    observer_membership = FactoryGirl.create(:membership, event: @event, attendance: 'Invited', role: 'Observer')
    expect(observer_membership).to be_valid
  end

  it 'sets a role automatically, if absent' do
    @membership.role = nil
    @membership.save
    expect(@membership.role).not_to be_nil
  end

  it 'sets an attendance automaticaly, if absent' do
    @membership.attendance = nil
    @membership.save
    expect(@membership.attendance).not_to be_nil
  end

end
