# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# MembershipChangeNotice prepares schedule change notices, sends to StaffMailer
class MembershipChangeNotice
  attr_reader :changed, :membership, :event

  def initialize(changed, membership)
    @changed = changed
    @membership = membership
    @event = membership.event
  end

  def run
    notify_coordinator
    notify_staff
  end

  private

  def changed_fields?
    changed.include?('attendance') || changed.include?('arrival_date') ||
      changed.include?('departure_date')
  end

  def invalid_lead_time_setting
    Setting.Emails.blank? || Setting.Emails[event.location].blank? ||
      Setting.Emails[event.location]['confirmation_lead'].blank? ||
      Setting.Emails[event.location]['confirmation_lead'] !~ /\A\d+\.\w+$/
  end

  def confirmation_lead_time
    return 6.months if invalid_lead_time_setting
    parts = Setting.Emails[event.location]['confirmation_lead'].split('.')
    parts.first.to_i.send(parts.last)
  end

  def valid_change?
    event.is_upcoming? && changed_fields?
  end

  def within_lead_time?
    event.start_date <= (Date.current + confirmation_lead_time)
  end

  def notify_coordinator
    return unless valid_change?
    send_notice(to: 'program_coordinator')
  end

  def notify_staff
    return unless valid_change? && within_lead_time?
    send_notice(to: 'confirmation_notices')
  end

  def arrival_date_change_message(msg)
    if changed.include?('arrival_date')
      msg << "\n" unless msg.empty?
      msg << "Arrival date was #{membership.arrival_date_was} and is now
        #{membership.arrival_date}.".squish
    end
    msg
  end

  def departure_date_change_message(msg)
    if changed.include?('departure_date')
      msg << "\n" unless msg.empty?
      msg << "Departure date was #{membership.departure_date_was} and is now
        #{membership.departure_date}.".squish
    end
    msg
  end

  def attendance_change_message
    msg = ''
    if changed.include?('attendance')
      msg = "Attendance was #{membership.attendance_was} and is now
        #{membership.attendance}.".squish
    end
    msg
  end

  def build_change_message
    msg = attendance_change_message
    msg = arrival_date_change_message(msg)
    departure_date_change_message(msg)
  end

  def send_notice(to:)
    msg = build_change_message
    return if msg.empty?
    EmailStaffConfirmationNoticeJob.perform_later(membership.id, msg, to)
  end
end
