# app/services/devise_fail.rb
# Copyright (c) 2020 Banff International Research Station
#
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Custom API login failure response
module DeviseFail
  class FailureApp < Devise::FailureApp
      def respond
        if request.controller_class.to_s.start_with? 'Api::'
          json_api_error_response
        else
          super
        end
      end

      def json_api_error_response
        self.status        = 401
        self.content_type  = 'application/json'
        self.response_body = { errors: { status: '401', message: i18n_message } }.to_json
      end
    end
end
