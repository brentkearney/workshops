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
      StaffMailer.notify_sysadmin(nil, { error: 'User has no associated person record', user: resource.inspect })
      self.destroy
      set_flash_message(:error, :has_no_person_record)
    elsif self.resource.role == 'member' && inactive_participant(resource)
      self.destroy
      set_flash_message(:error, :has_no_memberships)
    else
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource) do |format|
        #format.json {render json: resource }
        format.json {render json: { success: true, jwt: current_token, response: "Authentication successful" }}
      end
    end
  end

  private

  def inactive_participant(resource)
    # do you have any memberships where you're either an organizer or NOT not-invited or declined?
    self.resource.person.memberships.where("role LIKE '%Organizer%' OR (attendance != 'Not Yet Invited' AND attendance != 'Declined')").blank?
  end

  def current_token
    request.env['warden-jwt_auth.token']
  end
end
