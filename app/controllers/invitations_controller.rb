# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class InvitationsController < ApplicationController
  def new
    @events = Event.future
    @invitation = InvitationForm.new
  end

  def create
    Rails.logger.debug "\n\nInvitations Controller Received: #{params.inspect}\n"
    Rails.logger.debug "Strong params returns: #{invitation_params}\n"
    membership = find_membership
    Rails.logger.debug "Found membership: #{membership.inspect}\n\n"

    redirect_to invitations_new_path
  end

  private

  def find_membership
    param = invitation_params
    e = Event.find(param['event'])
    p = Person.find_by_email(param['person']['email'])
    Membership.where("event_id = #{e.id} AND person_id = #{p.id}")
  end

  def invitation_params
    params.require(:membership).permit(:event, :person => [ :email ])
  end
end

