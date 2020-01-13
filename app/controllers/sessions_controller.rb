# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class SessionsController < Devise::SessionsController
  respond_to :html
  layout "devise"

  # POST /sign_in
  def create
    cookies.delete(:read_notice2)
    self.resource = warden.authenticate!(auth_options)
    resource.validate

    if self.resource.person_id.nil?
      StaffMailer.notify_sysadmin(nil, { error: 'User has no associated person record', user: resource.inspect })
      self.destroy
      set_flash_message(:error, :has_no_person_record)
    elsif self.resource.role == 'member' && inactive_participant(resource)
      self.destroy
      set_flash_message(:error, :has_no_memberships)
    else
      set_flash_message!(:success, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    end
  end

  private

  def inactive_participant(resource)
    # do you have any memberships where you're either an organizer or NOT not-invited or declined?
    resource.person.memberships.where("role LIKE '%Organizer%' OR (attendance != 'Not Yet Invited' AND attendance != 'Declined')").blank?
  end
end
