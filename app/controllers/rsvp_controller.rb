# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class RsvpController < ApplicationController
  before_action :set_invitation, except: [:canadian_grants, :feedback]
  before_action :after_selection, only: %i[yes no maybe]

  # GET /rsvp/:otp
  def index
    unless @invitation.event.nil?
      @inv_event = @invitation.event
      @pc_email = GetSetting.email(@inv_event.location, 'program_coordinator')
    end
  end

  # GET /rsvp/yes/:otp
  # POST /rsvp/yes/:otp
  def yes
    SyncMember.new(@invitation.membership)
    @rsvp = RsvpForm.new(@invitation)
    @years = (1930..Date.current.year).to_a.reverse
    set_default_dates

    return unless request.post? && @rsvp.validate_form(yes_params)
    update_and_redirect(rsvp: :accept)
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
    return unless request.post?
    membership = Membership.find_by_id(feedback_params[:membership_id])
    message = feedback_params[:feedback_message]
    unless message.blank?
      EmailSiteFeedbackJob.perform_later('RSVP', membership.id, message)
    end
    redirect_to post_feedback_url(membership),
                success: 'Thanks for the feedback!'
  end

  private

  def post_feedback_url(membership)
    return membership.event.url if Rails.env.production?
    event_memberships_path(membership.event_id)
  end

  def set_organizer_message
    if params[:rsvp].blank?
      @organizer_message = ''
    else
      @organizer_message = message_params['organizer_message']
    end
  end

  def set_default_dates
    m = @invitation.membership
    m.arrival_date = m.event.start_date if m.arrival_date.blank?
    m.departure_date = m.event.end_date if m.departure_date.blank?
  end

  def update_and_redirect(rsvp:)
    @invitation.organizer_message = @organizer_message
    membership = @invitation.membership
    @invitation.send(rsvp)

    redirect_to rsvp_feedback_path(membership.id), success: 'Your attendance
      status was successfully updated. Thanks for your reply!'.squish
  end

  def set_invitation
    if params[:otp].blank?
      redirect_to invitations_new_path
    else
      @invitation = InvitationChecker.new(otp_params).invitation
    end
  end

  def after_selection
    set_organizer_message
    @invitation.errors.any? ? redirect_to(rsvp_otp_path) : set_organizer
  end

  def set_organizer
    @organizer = @invitation.membership.event.organizer.name
  end

  def otp_params
    params[:otp].tr('^A-Za-z0-9_-', '')
  end

  def message_params
    params.require(:rsvp).permit(:organizer_message)
  end

  def feedback_params
    params.permit(:membership_id, :feedback_message)
  end

  def yes_params
    params.require(:rsvp).permit(
      membership: [:arrival_date, :departure_date,
        :own_accommodation, :has_guest, :guest_disclaimer, :special_info,
        :share_email, :share_email_hotel],
      person: [:salutation, :firstname, :lastname, :gender,
        :affiliation, :department, :title, :academic_status, :phd_year, :email,
        :url, :phone, :address1, :address2, :address3, :city, :region,
        :postal_code, :country, :emergency_contact, :emergency_phone,
        :biography, :research_areas, :grant_id],
    )
  end
end
