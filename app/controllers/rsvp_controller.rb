# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class RsvpController < ApplicationController
  def index
    # legacy OTP urls = "https://www.domain.com/rsvp/?otp=$otp";

    if params[:otp].blank?
      redirect_to rsvp_new_path
    else
      @message = validate_otp
      Rails.logger.debug "\n\n" + '*' * 50 + "\n\n"
      Rails.logger.debug "OTP response: #{@message.inspect}"
      Rails.logger.debug "\n\n" + '*' * 50 + "\n\n"
    end
  end

  def new
    @events = Event.future
  end

  private

  def validate_otp
    LegacyConnector.new.check_rsvp(params[:otp])
  end
end
