# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Authenticates API access tokens
class Api::V1::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token
  protect_from_forgery with: :null_session
  before_action :parse_request, :authenticate_user_from_token!
  respond_to :json

  private

  def authenticate_user_from_token!
    @authenticated = false
    unauthorized && return if @json['api_key'].blank?

    payload_type = @json.keys.last.pluralize.upcase
    local_api_key = Setting.Site["#{payload_type}_API_KEY"]
    unavailable && return if local_api_key.blank?

    if Devise.secure_compare(local_api_key, @json['api_key'])
      @authenticated = true
    else
      unauthorized
    end
  end

  def parse_request
    if request.request_method == 'GET'
      @json = {}
      @json['api_key'] = request.headers.env['HTTP_API_KEY']
      @json['lecture'] = 'payload type placeholder'
      if action_name == 'lectures_on'
        @date = DateTime.parse(lectures_on_params.first)
        @room = lectures_on_params.last
      elsif action_name == 'lecture_data'
        @lecture_id = lecture_data_params
      end
    else
      @json = JSON.parse(request.body.read)
    end
  end

  def unauthorized
    head :unauthorized
  end

  def unavailable
    head :service_unavailable
  end

  def lectures_on_params
    params.require([:date, :room])
  end

  def lecture_data_params
    params.require(:id)
  end
end
