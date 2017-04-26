# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class RsvpController < ApplicationController
  before_filter :get_invitation, except: [:thank_you]

  # GET /rsvp/:otp
  def index
  end

  # GET /rsvp/yes/:otp
  def yes
    @rsvp = RsvpForm.new(@invitation)
  end

  # GET /rsvp/no/:otp
  def no
    @invitation.decline!
  end

  # GET /rsvp/maybe/:otp
  # POST /rsvp/maybe/:otp
  def maybe
    if request.post?
      @invitation.organizer_message = maybe_params['organizer_message']
      @invitation.maybe!
      remove_instance_variable(:@invitation)
      redirect_to rsvp_thank_you_path,
                  success: 'Invitation status successfully updated!'
    else
      @organizer = @invitation.membership.event.organizer.name
    end
  end

  def errors
  end

  # GET /rsvp/thank_you
  def thank_you
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

  def maybe_params
    params.permit(:organizer_message)
  end
end
