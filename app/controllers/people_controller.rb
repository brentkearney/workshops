# ./app/controllers/people_controller.rb
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class PeopleController < ApplicationController
  before_action :authenticate_user!

  def email_change
    Rails.logger.debug "\n\nPeopleController#email_change recieved: #{email_params.inspect}"
    @person = Person.find_by_id(email_params[:person_id])
    Rails.logger.debug "Retreived person: #{@person.inspect}\n\n"
  end

  def email_params
    params.permit(:person_id)
  end
end
