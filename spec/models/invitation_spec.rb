# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe 'Model validations: Invitation', type: :model do
  it 'has valid factory' do
    expect(build(:invitation)).to be_valid
  end

  it 'requires a membership' do
    i = build(:invitation, membership: nil)
    expect(i.valid?).to be_falsey
  end

  it 'requires invited_by' do
    i = build(:invitation)
    i.invited_by = nil
    expect(i.valid?).to be_falsey
  end

  it 'requires a code' do
    i = build(:invitation, code: nil)
    expect(i.valid?).to be_falsey
  end

  it 'generates a code upon initialization' do
    i = build(:invitation)
    expect(i.code).not_to be_blank
  end

  it 'sets expires on save' do
    i = build(:invitation)
    expect(i.expires).to be_nil
    i.save
    expect(i.expires).not_to be_nil
  end

  it 'derives expiry date from event.start_date - Setting.rsvp_expiry' do
    event = build(:event, future: true, online: false)
    membership = build(:membership, event: event)
    i = create(:invitation, membership: membership)

    duration = Invitation.duration_setting
    start_date = event.start_date.to_time
                      .in_time_zone(event.time_zone).beginning_of_day

    expect(i.expires).to eq(start_date - duration)
  end

  it 'for online events, sets expiry date to workshop end_date, end of day' do
    event = build(:event, online: true)
    membership = build(:membership, event: event)
    i = create(:invitation, membership: membership)

    end_time = event.end_date.to_time.end_of_day.in_time_zone(event.time_zone)
    expect(i.expires).to eq(end_time)
  end

  it 'updates membership fields when sending invites' do
    event = build(:event)
    membership = create(:membership, event: event, update_by_staff: true,
                        attendance: 'Not Yet Invited',
                        role: 'Backup Participant',
                        arrival_date: event.start_date - 1.day,
                        departure_date: event.end_date + 1.day)
    create(:invitation, membership: membership, invited_by: 'Foo').send_invite

    expect(membership.invited_by).to eq('Foo')
    expect(membership.invited_on).not_to be_nil
    expect(membership.attendance).to eq('Invited')
    expect(membership.role).to eq('Participant')
    expect(membership.arrival_date).to be_nil
    expect(membership.departure_date).to be_nil
  end
end
