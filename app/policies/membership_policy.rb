# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class MembershipPolicy
  attr_reader :current_user, :membership, :event, :model

  def initialize(current_user, model)
    @current_user = current_user
    @membership = model.nil? ? Membership.new : model
    @event = @membership.event
  end

  # Membership modification is not yet implemented
  def method_missing(name, *args)
    staff_and_admins
  end

  # Members cannot see memberships for events to which they
  # have not yet been invited, have declined invitation, or are
  # Backup Participants.
  class Scope < Struct.new(:current_user, :model)
    def resolve
      memberships = current_user.person.memberships.includes(:event)
                                .sort_by { |m| m.event.start_date }
      memberships.delete_if do |m|
        (m.role !~ /Organizer/ &&
          (m.attendance == 'Declined' || m.attendance == 'Not Yet Invited')) ||
          m.role == 'Backup Participant'
      end
    end
  end

  def index?
    true
  end

  def show?
    true
  end

  def use_email_address?
    return false if @current_user.nil?
    @current_user.is_organizer?(@event) || @current_user.is_admin? ||
      (@current_user.staff? && @current_user.location == @event.location) ||
      (@current_user.is_member?(@event) && @membership.share_email)
  end

  def view_details?
    return false if @current_user.nil?
    @membership.person == @current_user.person ||
      @current_user.is_organizer?(@event) || staff_and_admins
  end

  def invite?
    staff_and_admins
  end

  def staff_info?
    staff_and_admins
  end

  def allow_edit?
    return false if @current_user.nil?
    @membership.person == @current_user.person || staff_and_admins
  end

  def view_org_notes?
    return false if @current_user.nil?
    organizer_and_staff
  end

  private

  def organizer_and_staff
    return false if @current_user.nil?
    @current_user.is_organizer?(@event) || staff_and_admins
  end

  def staff_at_location
    return false if @current_user.nil?
    @current_user.staff? && @current_user.location == @event.location
  end

  def staff_and_admins
    return false if @current_user.nil?
    @current_user.is_admin? || staff_at_location
  end
end
