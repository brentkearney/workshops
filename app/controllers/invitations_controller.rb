# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class InvitationsController < ApplicationController

  def index
    redirect_to invitations_new_path
  end

  def new
    @events = Event.future
    @invitation = InvitationForm.new
  end

  def create
    @invitation = InvitationForm.new(invitation_params)
    if @invitation.valid?
      Rails.logger.debug "invitation is valid!\n"
      send_invitation(@invitation.membership)

      redirect_to invitations_new_path,
        success: 'A new invitation has been e-mailed to you!'
    else
      @events = Event.future
      render :new
    end
  end

  private

  def send_invitation(member)
    Invitation.new(membership: member,
                   invited_by: member.person.id).send_invite
  end

  def invitation_params
    params.require(:invitation).permit(:event, :email)
  end
end

