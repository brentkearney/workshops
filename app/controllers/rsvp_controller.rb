# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class RsvpController < ApplicationController
  before_filter :get_invitation

  def index
    # legacy OTP urls = "https://www.domain.com/rsvp/?otp=$otp";
    Rails.logger.debug "\n\n" + '*' * 50 + "\n\n"
    Rails.logger.debug "Checking #{otp_params}..."
    Rails.logger.debug "\n\n" + '*' * 50 + "\n\n"
  end

  def yes
    @rsvp = RsvpForm.new(@invitation)
  end

  def no
  end

  def maybe
  end


  private

  def get_invitation
    if params[:otp].blank?
      redirect_to invitations_new_path
    else
      @invitation = InvitationChecker.new(otp_params).invitation
      if @invitation.nil?
        redirect_to invitations_new_path,
          warning: 'That invitation code was not found! Please request a new one.'
      end
    end
  end

  def otp_params
    params[:otp].tr('^A-Za-z0-9_-','')
  end
end
