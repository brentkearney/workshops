# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Api::SessionsController < Devise::SessionsController
  skip_before_action :verify_signed_out_user
  respond_to :json

  # POST /api/login
  def create
    unless request.format == :json
      sign_out
      render status: 406, json: { message: "JSON requests only." } and return
    end

    resource = warden.authenticate!(auth_options)

    if resource.blank?
      render status: 401, json: { response: "Access denied." } and return
    end

    if resource.staff?
      sign_in(resource_name, resource)
      respond_with resource, location: after_sign_in_path_for(resource) do |format|
        format.json { render json: { success: true, jwt: current_token,
                                    response: "Authentication successful" } }
      end
    else
      revoke_token(resource)
      sign_out(resource)
      render status: 401, json: { message: "Staff access only." } and return
    end
  end

  # DELETE /api/logout
  def destroy
    token = params['Authorization'].split('Bearer ').last
    secret = ENV['DEVISE_JWT_SECRET_KEY']
    u = JWT.decode(token, secret, true, algorithm: 'HS256', verify_jti: true)[0]
    user = ApiUser.find_by_jti(u['jti'])

    super if user.blank?
    revoke_token(user)
    sign_out(user)
    set_flash_message!(:success, :signed_out)
    render status: 200, json: { message: "Signed out." }
  end

  private

  def revoke_token(user)
    user.update_column(:jti, generate_jti)
  end

  def current_token
    request.env['warden-jwt_auth.token']
  end

  def generate_jti
    SecureRandom.uuid
  end
end
