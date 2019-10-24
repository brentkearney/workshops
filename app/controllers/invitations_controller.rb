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
      members = event.memberships.where.not(role: "Backup Participant")
                     .where(attendance: "Not Yet Invited")
      full = event_full?(event, members)
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

  def send_all_invites
    event = Event.find_by_id(event_param['event_id'])
    redirect_to root_path,
        error: 'Event not found.' and return if event.blank?

    unless policy(event).send_invitations?
      redirect_to event_memberships_path(event),
          error: 'Access to this feature is restricted.' and return
    end

    members = event.memberships.where.not(role: "Backup Participant")
                   .where(attendance: "Not Yet Invited")
    if members.empty?
      redirect_to event_memberships_path(event),
          error: 'There are no Not-Yet-Invited, non-Backup Participants
          to send invitations to.'.squish and return
    end

    full = event_full?(event, members)
    if full == :max_participants
      redirect_to event_memberships_path(event),
          error: "You may not invite more than
                  #{event.max_participants} participants.".squish and return
    elsif full == :max_observers
      redirect_to event_memberships_path(event),
          error: "You may not invite more than
                  #{event.max_observers} observers.".squish and return
    else
      pause_membership_syncing(event)
      members.each do |membership|
        membership.person.member_import = true # skip validations on save
        send_invitation(membership, current_user.name)
      end
      redirect_to event_memberships_path(event),
        success: "Invitations were sent to: #{members.size} participants."
    end
  end

  private

  def is_reinvite?(membership)
    %w(Invited Undecided).include?(membership.attendance)
  end

  def event_full?(event, members=[])
    invited_participants = members.select { |m| m.role != 'Observer' }.count
    if event.num_invited_participants + invited_participants > event.max_participants
      return :max_participants
    end
    invited_observers = members.select { |m| m.role == 'Observer' }.count
    return if invited_observers == 0
    if event.num_invited_observers + invited_observers > event.max_observers
      return :max_observers
    end
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
