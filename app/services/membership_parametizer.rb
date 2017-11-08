# Copyright (c) 2017 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Authorizes and tweaks posted form data
class MembershipParametizer
  include Pundit
  attr_reader :form_data, :current_user, :person_data

  def initialize(membership, form_data, current_user)
    @form_data = form_data
    @membership = membership
    @current_user = current_user
    @person_data = form_data.delete(:person_attributes)

    update_membership
    update_person
  end

  def update_membership
    db_member = Membership.find(@membership.id)
    db_member.assign_attributes(form_data)
    if db_member.changed?
      form_data['updated_by'] = @current_user.name
      @membership.sync_remote = true
    end
  end

  def update_person
    person = Person.find(@membership.person_id)
    person.assign_attributes(person_data)
    if person.changed?
      person_data['updated_by'] = @current_user.name
      form_data['person_attributes'] = person_data
      @membership.sync_remote = true
    end
  end

  def data
    @membership.update_by_staff = true if policy(@membership).extended_stay?
    form_data
  end
end
