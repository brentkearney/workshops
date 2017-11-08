# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'SortedMembers' do
  before do
    Event.destroy_all
    @event = create(:event)
  end

  after :each do
    Membership.destroy_all
  end

  it '.initialize' do
    sm = SortedMembers.new(@event)
    expect(sm.class).to eq(SortedMembers)
  end

  it '.make_members_hash' do
    membership = create(:membership, event: @event, attendance: 'Declined')

    memberships = SortedMembers.new(@event).make_members_hash

    expect(memberships).to eq({"Declined" => [membership]})
  end

  it '.sort_by_attendance' do
    Membership::ATTENDANCE.shuffle.each do |status|
      create(:membership, event: @event, attendance: status)
    end

    sm = SortedMembers.new(@event)
    sm.make_members_hash
    sorted_attendance = sm.sort_by_attendance.keys

    sorted_attendance.each_with_index do |status, index|
      expect(Membership::ATTENDANCE.fetch(index)).to eq(status)
    end
  end

  context '.sort_by_role_and_name' do
    it 'roles are in the order specified by the model' do
      Membership::ROLES.shuffle.each do |role|
        create(:membership, event: @event, attendance: 'Not Yet Invited', role: role)
      end

      sm = SortedMembers.new(@event)
      sm.make_members_hash
      sorted_members = sm.sort_by_role_and_name

      sorted_members["Not Yet Invited"].each_with_index do |member, index|
        expect(Membership::ROLES.fetch(index)).to eq(member.role)
      end
    end

    it 'names are in alphabetical order' do
      letters = ('A'..'M').to_a
      letters.shuffle.each do |letter|
        p = create(:person, lastname: "#{letter}person")
        create(:membership, event: @event, person: p, attendance: 'Confirmed')
      end

      sm = SortedMembers.new(@event)
      sm.make_members_hash
      sorted_members = sm.sort_by_role_and_name

      sorted_members['Confirmed'].each_with_index do |member, index|
        expect(letters.fetch(index)).to eq(member.person.lastname[0])
      end

    end
  end

  it '.memberships' do
    p1 = create(:person, lastname: "Aperson")
    p2 = create(:person, lastname: "Bperson")
    p3 = create(:person, lastname: "Cperson")
    p4 = create(:person, lastname: "Dperson")
    m1 = create(:membership, event: @event, person: p2, attendance: 'Confirmed')
    m2 = create(:membership, event: @event, person: p1, attendance: 'Confirmed')
    m3 = create(:membership, event: @event, person: p3, attendance: 'Invited')
    m4 = create(:membership, event: @event, person: p4, attendance: 'Invited')

    memberships = SortedMembers.new(@event).memberships

    expect(memberships['Confirmed']).to eq([m2, m1]) # alphabetical order
    expect(memberships['Invited']).to match_array([m3, m4])
    expect(memberships['Declined']).to be_falsey
    expect(memberships['Not Yet Invited']).to be_falsey
    expect(memberships['Undecided']).to be_falsey
  end
end
