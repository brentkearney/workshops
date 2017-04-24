# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class RsvpController < ApplicationController
  before_filter :get_invitation

  def index

  end

  def yes
    @rsvp = RsvpForm.new(@invitation)
  end

  def no
    @invitation.decline!
  end

  def maybe
    @organizer = @invitation.membership.event.organizer.name
  end

  def errors
  end


  private

  def get_invitation
    if params[:otp].blank?
      redirect_to invitations_new_path
    else
      @invitation = InvitationChecker.new(otp_params).invitation
    end
  end

  def otp_params
    params[:otp].tr('^A-Za-z0-9_-','')
  end
end
