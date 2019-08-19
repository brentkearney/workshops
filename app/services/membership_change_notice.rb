# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# MembershipChangeNotice prepares membership change notices, sends to mailers
class MembershipChangeNotice
  attr_reader :changed, :membership, :event

  def initialize(changed, membership)
    @changed = changed.to_h
    @membership = membership
    @event = membership.event
  end

  def run
    if valid_change?
      notify_coordinator
      notify_staff
    end
    notify_organizer if @changed.keys.include?('attendance')
  end

  # if these fields change, notify staff
  NOTIFY_FIELDS = %w(attendance arrival_date departure_date special_info
                     has_guest own_accommodation)

  private

  def changed_fields?
    !(NOTIFY_FIELDS & changed.keys).empty?
  end

  def confirmation_lead_time
    GetSetting.confirmation_lead_time(event.location)
  end

  def valid_change?
    changed_fields? && event.upcoming? &&
      membership.updated_by != 'Workshops importer'
  end

  def within_lead_time?
    event.start_date <= (Date.current + confirmation_lead_time)
  end

  def changed_by_member?
    membership.updated_by == membership.person.name
  end

  def notify_coordinator
    send_notice(to: 'program_coordinator') if changed_by_member?
  end

  def notify_staff
    return unless within_lead_time?
    send_notice(to: 'confirmation_notices')
  end

  def build_change_message
    msg = []
    NOTIFY_FIELDS.each do |field|
      field_was = add_changed_field?(field)
      if field_was
        msg << %(#{field.titleize} was "#{field_was}" and is now
          "#{membership.send(field)}".).squish
      end
    end
    message_hash(msg)
  end

  def message_hash(msg)
    {
      message: msg,
      updated_by: membership.updated_by
    }
  end

  def add_changed_field?(field)
    return false unless changed.keys.include?(field)
    membership.saved_changes.transform_values(&:first)[field]
  end

  def send_notice(to:)
    msg = build_change_message
    return if msg.empty?
    EmailStaffConfirmationNoticeJob.perform_later(membership.id, msg, to)
  end

  def notify_organizer
    return if @membership.is_rsvp # Invitation class already sent notice
    args = { 'attendance_was' => @changed['attendance'],
             'attendance' => @membership.attendance }

    EmailOrganizerNoticeJob.perform_later(@membership.id, args)
  end
end
