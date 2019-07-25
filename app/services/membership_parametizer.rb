# Copyright (c) 2017 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Authorizes and tweaks posted form data
class MembershipParametizer
  include Pundit
  attr_accessor :form_data, :current_user, :person_data, :user_update,
                :verify_email

  def initialize(membership, form_data, current_user)
    @form_data = form_data
    @membership = membership
    @current_user = current_user
    @person_data = @form_data.delete(:person_attributes)
    update_membership
    update_person
  end

  def update_membership
    db_member = Membership.find(@membership.id)
    db_member.assign_attributes(@form_data)
    if db_member.changed?
      @form_data['updated_by'] = @current_user.name
      update_role?(db_member)
      @membership.update_remote = true
    end
  end

  def update_role?(updated_member)
    return unless updated_member.changed_attributes.key?('role')
    form_data.delete('role') unless role_edit_allowed?(updated_member)
  end

  def role_edit_allowed?(updated_member)
    # To and from Organizer role
    policy(@membership).edit_role? &&
      MembershipPolicy.new(current_user, updated_member).edit_role?
  end

  def update_person
    return if @person_data.blank?
    person = Person.find(@membership.person_id)
    person.assign_attributes(@person_data)
    return unless person.changed?
    @person_data = person.attributes
    data_massage
    @membership.update_remote = true
    @form_data['person_attributes'] = @person_data
  end

  def data_massage
    @person_data['updated_by'] = @current_user.name
    email_update if @person_data['email'] != @membership.person.email
    update_gender?
    numeric_phd_year?
  end

  def email_update
    new_email = @person_data.delete('email')
    sync = SyncPerson.new(@membership.person, new_email)
    if sync.has_conflict?
      create_email_change_confirmation(sync) ||
        @person_data['email'] = new_email # create validation error
    else
      update_user_email(new_email) # sends reconfirmation email
      person = sync.change_email
      @person_data = person.attributes.merge(@person_data)
      @person_data['id'] = person.id
      @membership.person_id = person.id
    end
  end

  def create_email_change_confirmation(sync)
    return unless @current_user.person_id == @membership.person_id
    @verify_email = true # forward to email confirmation form
    sync.create_change_confirmation(sync.find_other_person,
                                    @membership.person,
                                    reverse_emails: true)
    @person_data['email'] = @membership.person.email
  end

  def update_user_email(new_email)
    user = User.find_by_person_id(@membership.person_id)
    return if user.nil? || user.email == new_email
    @user_update = true if @current_user.person_id == user.person_id
    user.email = new_email
    user.save
  end

  def numeric_phd_year?
    person_data['phd_year'] = nil unless person_data['phd_year'] =~ /\A[0-9]*\Z/
  end

  def update_gender?
    if @person_data['gender'].blank? || !policy(@membership).edit_personal_info?
      @person_data['gender'] = Person.find(@membership.person_id).gender
    end
  end

  def data
    @membership.update_by_staff = true if policy(@membership).staff_update?
    @form_data
  end

  def new_user_email?
    @user_update || false
  end
end
