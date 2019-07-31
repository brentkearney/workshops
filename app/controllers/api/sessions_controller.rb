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

    sign_out_and_respond(resource) and return unless resource.staff?

    sign_in(resource_name, resource)
    respond_with resource, location: after_sign_in_path_for(resource) do |format|
      format.json { render json: { success: true, jwt: current_token,
                                  response: "Authentication successful" } }
    end
  end

  # DELETE /api/logout
  def destroy
    super and return if params['Authorization'].blank?
    user = ApiUser.find_by_jti(decode_token)
    super and return if user.blank?
    revoke_token(user)
    super
  end

  private

  def sign_out_and_respond(resource)
    revoke_token(resource)
    sign_out(resource)
    render status: 401, json: { message: "Staff access only." }
  end


  def decode_token
    token = params['Authorization'].split('Bearer ').last
    secret = ENV['DEVISE_JWT_SECRET_KEY']
    JWT.decode(token, secret, true, algorithm: 'HS256',
      verify_jti: true)[0]['jti']
  end

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
