# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Api::SessionsController < Devise::SessionsController
  # prepend_before_filter :allow_params_authentication!, only: :create
  respond_to :json

  # POST /api/login
  def create
    Rails.logger.debug "\n\nRequest format: #{request.format}\n"
    Rails.logger.debug "\nParams: #{params.inspect}\n"

    if request.format != :json
      Rails.logger.debug "\nRequest not JSON, signing out!\n"
      sign_out
      render status: 406, json: { message: "JSON requests only." } and return
    end

    Rails.logger.debug "\nAttempting to authenticate with #{auth_options.inspect}...\n"
    resource = warden.authenticate!(auth_options)

    if resource.blank?
      sign_out
      render status: 401, json: { response: "Access denied." } and return
    end

    if resource.staff?
      sign_in(resource_name, resource)
      yield resource if block_given?
      Rails.logger.debug "\nResponding with jwt: #{current_token}\n"
      respond_with resource, location: after_sign_in_path_for(resource) do |format|
        format.json { render json: { success: true, jwt: current_token, response: "Authentication successful" } }
      end
    else
      sign_out
      render status: 401, json: { message: "Staff access only." } and return
    end
  end

  private

  def current_token
    request.env['warden-jwt_auth.token']
  end
end
