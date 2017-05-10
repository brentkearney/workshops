# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class RsvpController < ApplicationController
  before_filter :get_invitation, except: [:feedback]
  before_filter :set_organizer_name, only: [:yes, :no, :maybe]

  @update_message = 'Your attendance status was successfully updated.
    Thanks for your reply!'

  # GET /rsvp/:otp
  def index
  end

  # GET /rsvp/yes/:otp
  # POST /rsvp/yes/:otp
  def yes
    @rsvp = RsvpForm.new(@invitation)
    @years = 1930..Date.current.year

    if request.post? && @rsvp.validate_form(yes_params)
      update_and_redirect(rsvp: :accept)
    end
  end

  # GET /rsvp/no/:otp
  # POST /rsvp/no/:otp
  def no
    update_and_redirect(rsvp: :decline) if request.post?
  end

  # GET /rsvp/maybe/:otp
  # POST /rsvp/maybe/:otp
  def maybe
    update_and_redirect(rsvp: :maybe) if request.post?
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

  def update_and_redirect(rsvp:)
    @invitation.organizer_message = message_params['organizer_message']
    membership = @invitation.membership
    @invitation.send(rsvp)
    redirect_to rsvp_feedback_path(membership.id), success: @update_message
  end

  def get_invitation
    if params[:otp].blank?
      redirect_to invitations_new_path
    else
      @invitation = InvitationChecker.new(otp_params).invitation
    end
  end

  def set_organizer_name
    @organizer = @invitation.membership.event.organizer.name
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

  def yes_params
    params.require(:rsvp).permit(
      membership: [:arrival_date, :departure_date,
        :own_accommodation, :has_guest, :guest_disclaimer, :special_info,
        :share_email],
      person: [:salutation, :firstname, :lastname, :gender,
        :affiliation, :department, :title, :academic_status, :phd_year, :email,
        :url, :phone, :address1, :address2, :address3, :city, :region,
        :postal_code, :country, :emergency_contact, :emergency_phone,
        :biography, :research_areas]
    )
  end
end
