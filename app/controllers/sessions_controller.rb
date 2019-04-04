# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class SessionsController < Devise::SessionsController
  respond_to :json

  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate!(auth_options)

    if self.resource.person_id.nil?
      set_flash_message(:error, :has_no_person_record)
      StaffMailer.notify_sysadmin(nil, { error: 'User has no associated person record', user: resource.inspect })
      sign_out(resource)
      respond_to_on_destroy
    elsif self.resource.role == 'member' && inactive_participant(resource)
      set_flash_message(:error, :has_no_memberships)
      sign_out(resource)
      respond_to_on_destroy
    else
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    end
  end

  private

  def inactive_participant(resource)
    # do you have any memberships where you're either an organizer or NOT not-invited or declined?
    self.resource.person.memberships.where("role LIKE '%Organizer%' OR (attendance != 'Not Yet Invited' AND attendance != 'Declined')").blank?
  end
end
