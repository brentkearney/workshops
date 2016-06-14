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
    false
  end

  # Members cannot see memberships for events to which they
  # have not yet been invited, have declined invitation, or are
  # Backup Participants.
  class Scope < Struct.new(:current_user, :model)
    def resolve
      memberships = current_user.person.memberships.includes(:event).sort_by {|m| m.event.start_date }
      memberships.delete_if do |m|
        (m.role !~ /Organizer/ && (m.attendance == 'Declined' || m.attendance == 'Not Yet Invited')) ||
            m.role == 'Backup Participant'
      end
    end
  end

  def use_email_address?
    @current_user.is_organizer?(@event) || @current_user.is_admin? ||
        (@current_user.staff? && @current_user.location == @event.location) ||
        (@current_user.is_member?(@event) && @membership.share_email)
  end

  def view_details?
    @current_user.is_organizer?(@event) || @current_user.is_admin? ||
        (@current_user.staff? && @current_user.location == @event.location)
  end

  def invite?
    allow_staff_and_admins
  end

  private

  def staff_at_location
    @current_user.staff? && @current_user.location == @event.location
  end

  def allow_staff_and_admins
    if @current_user
      @current_user.is_admin?  || staff_at_location
    end
  end
end