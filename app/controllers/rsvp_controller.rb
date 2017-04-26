# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class RsvpController < ApplicationController
  before_action :set_event

  def index
    redirect_to event_path(@event) unless valid_otp
  end

  private

  def valid_otp
    false
  end
end
