# ./app/controllers/invitations_controller.rb
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class InvitationsController < ApplicationController
  def index
    redirect_to invitations_new_path
  end

  def new
    @events = future_events
    @code = Event.find(event_param['id']).code unless event_param.blank?
    @code ||= ''
    @invitation = InvitationForm.new
  end

  def create
    @invitation = InvitationForm.new(invitation_params)
    if @invitation.valid?
      send_invitation(@invitation.membership)

      redirect_to invitations_new_path,
        success: 'A new invitation has been sent!'
    else
      @events = future_events
      render :new
    end
  end

  def send_invite
    membership = Membership.find_by_id(membership_param['membership_id'])
    redirect_to root_path,
                error: 'Membership not found.' and return if membership.nil?

    event = membership.event
    unless policy(event).send_invitations?
      redirect_to event_memberships_path(event),
          error: 'Access to this feature is restricted.' and return
    end

    unless is_reinvite?(membership)
      full = event_full?(event, [membership])
      if full == :max_participants
        redirect_to event_memberships_path(event),
          error: 'This event is already full.' and return
      elsif full == :max_observers
        redirect_to event_memberships_path(event),
          error: "You may not invite more than
                #{event.max_observers} observers.".squish and return
      end
    end

    pause_membership_syncing(event)
    send_invitation(membership, current_user.name)
    redirect_to event_memberships_path(event),
                success: "Invitation sent to #{membership.person.name}"
  end

  private

  def is_reinvite?(membership)
    %w(Invited Undecided).include?(membership.attendance)
  end

  def pause_membership_syncing(event)
    event.sync_time = DateTime.now
    event.save
  end

  def send_invitation(member, invited_by = false)
    (invited_by = @current_user.name if @current_user) unless invited_by
    Invitation.new(membership: member,
                   invited_by: invited_by || member.person.name).send_invite
  end

  def future_events
    Event.where("start_date >= ?", expires_before).order(:start_date)
  end

  def expires_before
    Date.today + Invitation::EXPIRES_BEFORE
  end

  def invitation_params
    params.require(:invitation).permit(:event, :email)
  end

  def membership_param
    params.permit(:membership_id)
  end

  def event_param
    params.permit(:id, :event_id)
  end
end
