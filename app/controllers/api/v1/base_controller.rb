# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Api::V1::BaseController < ApplicationController
  skip_before_filter :verify_authenticity_token
  protect_from_forgery with: :null_session
  before_filter :parse_request, :authenticate_user_from_token!
  respond_to :json

  private
  def authenticate_user_from_token!
    @updated_by = 'Automated Video System'
    @authenticated = false

    if !@json['api_key']
      unauthorized
    else
      api_key = ENV['LECTURES_API_KEY']
      if Devise.secure_compare(api_key, @json['api_key'])
        @authenticated = true
      else
        unauthorized
      end
    end
  end

  def parse_request
    @json = JSON.parse(request.body.read)
  end

  def unauthorized
    render nothing: true, status: :unauthorized
  end
end
