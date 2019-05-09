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

  def allowed_fields?
    case current_user.role
    when 'admin', 'super_admin'
      all_fields
    when 'staff'
      staff_at_location ? all_fields - [:org_notes] : []
    when 'member'
      return organizer_fields if organizer?
      return [] unless member_self?
      all_fields - [:id, :event_id, :person_id, :role, :room, :room_notes,
                    :attendance, :reviewed, :billing, :special_info,
                    :staff_notes, :org_notes, :own_accommodation, :has_guest,
                    :guest_disclaimer]
    else
      []
    end
  end

  def organizer_fields
    if member_self?
      all_fields - [:id, :event_id, :person_id, :room, :reviewed, :billing,
        :staff_notes, :has_guest, :guest_disclaimer]
    else
      [:id, :event_id, :person_id, :share_email, :role, :attendance, :org_notes,
      person_attributes: [:id, :salutation, :firstname, :lastname, :email, :url,
                         :affiliation, :department, :title, :research_areas,
                         :biography]]
    end
  end

  def all_fields
    [:id, :event_id, :person_id, :share_email, :role, :attendance,
     :arrival_date, :departure_date, :reviewed, :billing, :room, :room_notes,
     :special_info, :staff_notes, :org_notes, :own_accommodation, :has_guest,
     :guest_disclaimer, :share_email, :share_email_hotel,
     person_attributes: [:salutation, :firstname, :lastname, :email, :phone,
                         :gender, :affiliation, :department, :title, :url,
                         :academic_status, :research_areas, :biography, :id,
                         :address1, :address2, :address3, :city, :region,
                         :postal_code, :country, :phd_year, :emergency_contact,
                         :emergency_phone, :grant_id]]
  end

  def index?
    true
  end

  def show?
    self_organizer_staff || confirmed_or_invited_member
  end

  def edit?
    self_organizer_staff
  end

  def update?
    self_organizer_staff
  end

  def add?
    organizer_and_staff
  end

  def show_email_address?
    return false if @current_user.nil?
    (organizer_and_staff && @membership.share_email) || is_member_and_shared
  end

  def is_member_and_shared
    @current_user.is_confirmed_member?(@event) && @membership.share_email &&
      @membership.attendance == 'Confirmed'
  end

  # Allow the use of emails when they are not shared by the member
  def use_email_addresses?
    return false if @current_user.nil?
    organizer_and_staff
  end

  def show_not_shared?
    return false if @current_user.nil?
    @current_user.is_confirmed_member?(@event) && !@membership.share_email
  end

  def edit_person?
    self_organizer_staff
  end

  def edit_membership?
    self_organizer_staff
  end

  def delete_membership?
    organizer_and_staff
  end

  def edit_role?
    @membership.role =~ /Organizer/ ? staff_and_admins : organizer_and_staff
  end

  def edit_dates?
    staff_and_admins || @membership.person == @current_user.person
  end

  def extended_stay?
    staff_and_admins
  end

  def edit_hotel?
    staff_and_admins
  end

  def show_personal_info?
    return false if @current_user.nil?
    staff_and_admins || @membership.person == @current_user.person
  end

  def edit_personal_info?
    show_personal_info?
  end

  def edit_attendance?
    organizer_and_staff
  end

  def organizer_notes?
    return false if @current_user.nil?
    @current_user.is_organizer?(@event) || @current_user.is_admin?
  end

  def show_details?
    self_organizer_staff
  end

  def invite?
    return true if allow_staff_and_admins
    current_user.is_organizer?(event)
  end

  def hotel_and_billing?
    staff_and_admins
  end

  private

  def confirmed_member
    @membership.attendance == 'Confirmed' ||
      @membership.attendance == 'Undecided'
  end

  def confirmed_or_invited_member
    %w(Confirmed Undecided Invited).include?(@membership.attendance)
  end

  def self_organizer_staff
    organizer_and_staff || member_self?
  end

  def member_self?
    return false if @current_user.nil?
    @membership.person == @current_user.person
  end

  def organizer_and_staff
    organizer? || staff_and_admins
  end

  def organizer?
    return false if @current_user.nil? || @event.nil?
    @current_user.is_organizer?(@event)
  end

  def staff_and_admins
    return false if @current_user.nil?
    staff_at_location || @current_user.is_admin?
  end

  def staff_at_location
    return false if @current_user.nil? || @event.nil?
    @current_user.staff? && @current_user.location == @event.location
  end
end
