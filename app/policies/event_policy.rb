# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class EventPolicy
  attr_reader :current_user, :event

  def initialize(current_user, model)
    @current_user = current_user
    @event = model.nil? ? Event.new : model
  end

  def method_missing(name, *args)
    if current_user
      if staff_at_location
        event.template && name =~ /edit|update/
      else
        current_user.is_admin?
      end
    end
  end

  # Only staff can see template events at their location
  class Scope < Struct.new(:current_user, :model)
    def resolve
      if current_user && (current_user.staff? || current_user.admin?)
        return model.all.order(:start_date) if current_user.is_admin?

        location = current_user.location
        model.where
             .not('(template = ? AND location != ?)', true, location)
             .order(:start_date)
      else
        model.where(template: false).order(:start_date)
      end
    end
  end

  def update?
    allow_orgs_and_staff
  end

  def edit?
    allow_orgs_and_staff
  end

  def may_edit
    all_fields = event.attributes.keys - %w[id updated_by created_at updated_at
                                            confirmed_count publish_schedule]
    case current_user.role
    when 'admin', 'super_admin'
      all_fields
    when 'staff'
      all_fields - %w[code name start_date end_date location event_type
                      time_zone max_participants template]
    when 'member'
      if current_user.is_organizer?(event)
        %w[short_name description press_release]
      else
        []
      end
    else
      []
    end
  end

  def show?
    if event.template
      allow_staff_and_admins
    else
      true
    end
  end

  def delete?
    current_user.super_admin?
  end

  def show_add_members?
    return false if @event.past?
    allow_orgs_and_staff
  end

  def view_attendance_status?(status)
    return true if allow_orgs_and_staff
    if current_user
      ['Confirmed', 'Invited', 'Undecided'].include?(status)
    end
  end

  def view_email_addresses?
    if current_user
      current_user.is_member?(event) || current_user.is_admin? || staff_at_location
    end
  end

  def show_email_buttons?(status)
    return true if allow_orgs_and_staff
    member_of_event? && status == 'Confirmed'
  end

  # Allow the use of emails when they are not shared by the member
  def use_email_addresses?
    if current_user
      current_user.is_organizer?(event) || allow_staff_and_admins
    end
  end

  def send_invitations?
    return false if event.start_date < Date.current
    return true if allow_staff_and_admins
    current_user.is_organizer?(event)
  end

  def sync?
    if event.end_date >= Date.today && !event.template
      allow_orgs_and_staff unless Rails.env.test?
    end
  end

  def view_details?
    view_email_addresses?
  end

  def event_staff?
    allow_staff_and_admins
  end

  private

  def staff_at_location
    return false unless current_user
    current_user.staff? && current_user.location == event.location
  end

  def allow_staff_and_admins
    return false unless current_user
    current_user.is_admin?  || staff_at_location
  end

  def allow_orgs_and_staff
    return false unless current_user
    current_user.is_organizer?(event) || current_user.is_admin?  || staff_at_location
  end

  def member_of_event?
    return false unless current_user
    member = Membership.where(person: current_user.person, event: @event).first
    return false if member.blank?
    ['Confirmed', 'Invited', 'Undecided'].include?(member.attendance)
  end
end
