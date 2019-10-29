# app/forms/invite_members_form.rb
#
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# For views/memberships/invite.html.erb
class InviteMembersForm < ComplexForms
  attr_accessor :invited, :memberships

  def initialize(event, current_user)
    @event = event
    @current_user = current_user
    self.invited = []
    self.memberships = []
  end

  def process(membership_ids)
    Rails.logger.debug "\n\n.process received: #{membership_ids}\n\n"
    membership_ids.each do |id|
      membership = Membership.find(id.to_i)
      Rails.logger.debug "\t* #{membership.person.name} (#{membership.attendance})\n"
      @memberships << membership
    end
  end

  def send_invitations
    pause_membership_syncing unless @memberships.empty?
    @memberships.each do |membership|
      # if membership.attendance == 'Not Yet Invited'
      membership.person.member_import = true # skip validations on save
      Invitation.new(membership: membership,
                     invited_by: @current_user.person.name).send_invite
      # else
      # end
    end
  end

  def max_participants?
    invited = @memberships.select { |m| m.role != 'Observer' }.count
    @event.num_invited_participants + invited > @event.max_participants
  end

  def max_observers?
    invited_observers = @memberships.select { |m| m.role == 'Observer' }.count
    return false if invited_observers == 0
    @event.num_invited_observers + invited_observers > @event.max_observers
  end

  private

  def pause_membership_syncing
    @event.sync_time = DateTime.now
    @event.save
  end
end
