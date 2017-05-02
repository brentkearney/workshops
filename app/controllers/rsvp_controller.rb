# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class RsvpController < ApplicationController
  before_filter :get_invitation, except: [:feedback]

  @update_message = 'Your attendance status was successfully updated.
    Thanks for your reply!'

  # GET /rsvp/:otp
  def index
  end

  # GET /rsvp/yes/:otp
  # POST /rsvp/yes/:otp
  def yes
    @rsvp = RsvpForm.new(@invitation)
  end

  # GET /rsvp/no/:otp
  # POST /rsvp/no/:otp
  def no
    if request.post?
      @invitation.organizer_message = message_params['organizer_message']
      membership = @invitation.membership
      @invitation.decline!
      redirect_to rsvp_feedback_path(membership.id), success: @update_message
    else
      @organizer = @invitation.membership.event.organizer.name
    end
  end

  # GET /rsvp/maybe/:otp
  # POST /rsvp/maybe/:otp
  def maybe
    if request.post?
      @invitation.organizer_message = message_params['organizer_message']
      membership = @invitation.membership
      @invitation.maybe!

      redirect_to rsvp_feedback_path(membership.id), success: @update_message
    else
      @organizer = @invitation.membership.event.organizer.name
    end
  end

  # GET /rsvp/feedback
  # POST /rsvp/feedback
  def feedback
    if request.post?
      membership = Membership.find(feedback_params[:membership_id])
      message = feedback_params[:feedback_message]
      StaffMailer.site_feedback(section: 'RSVP', membership: membership,
          message: message).deliver_now
      redirect_to event_memberships_path(membership.event),
        success: 'Thanks for the feedback!'
    else
      render :feedback
    end
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

  def message_params
    params.permit(:organizer_message)
  end

  def feedback_params
    params.permit(:membership_id, :feedback_message)
  end
end
