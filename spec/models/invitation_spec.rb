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
    event = build(:event, future: true, event_format: 'Physical')
    membership = build(:membership, event: event)
    i = create(:invitation, membership: membership)

    duration = Invitation.duration_setting
    start_date = event.start_date.to_time
                      .in_time_zone(event.time_zone).beginning_of_day

    expect(i.expires).to eq(start_date - duration)
  end

  it 'for online events, sets expiry date to workshop end_date, end of day' do
    event = build(:event, event_format: 'Online')
    membership = build(:membership, event: event)
    i = create(:invitation, membership: membership)

    end_time = event.end_date.to_time.end_of_day.in_time_zone(event.time_zone)
    expect(i.expires).to eq(end_time)
  end

  it 'for hybrid events & virtual attendees, sets expiry date to workshop
      end_date, end of day' do
    event = build(:event, event_format: 'Hybrid')
    membership = build(:membership, event: event, role: 'Virtual Participant')
    i = create(:invitation, membership: membership)

    end_time = event.end_date.to_time.end_of_day.in_time_zone(event.time_zone)
    expect(i.expires).to eq(end_time)
  end

  context '.send_invite' do
    it 'updates membership fields' do
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

    it 'sets the mailer template according to event format & type' do
      membership = create(:membership, attendance: 'Not Yet Invited')
      invitation = create(:invitation, membership: membership)

      event_format = membership.event.event_format
      event_type = membership.event.event_type

      invitation.send_invite
      template = invitation.templates['template_name']
      expect(template).to eq("#{event_format}-#{event_type}-Not Yet Invited")
    end
  end

  context '.send_reminder' do
    it 'updates the invite_reminders field with a datetime and name' do
      membership = create(:membership, attendance: 'Not Yet Invited')
      invitation = create(:invitation, membership: membership)
      invitation.send_invite

      expect(invitation.membership.invite_reminders).to be_empty
      invitation.send_reminder

      reminders = invitation.membership.invite_reminders
      expect(reminders).not_to be_empty
      expect(reminders.values.last).to eq('FactoryBot')

      reminded_on = reminders.keys.first.strftime("%Y-%m-%d %H:%M")
      expect(reminded_on).to eq(DateTime.now.strftime("%Y-%m-%d %H:%M"))
    end

    it 'sets the mailer template' do
      membership = create(:membership, attendance: 'Invited')
      invitation = create(:invitation, membership: membership)

      event_format = membership.event.event_format
      event_type = membership.event.event_type

      invitation.send_reminder
      template = invitation.templates['template_name']
      expect(template).to eq("#{event_format}-#{event_type}-Invited")
    end
  end
end
