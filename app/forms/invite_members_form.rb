# app/forms/invite_members_form.rb
#
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# For views/memberships/invite.html.erb
class InviteMembersForm < ComplexForms
  attr_reader :error_msg, :success_msg

  def initialize(event, current_user)
    @event = event
    @current_user = current_user
    @invited = []
    @reminded = []
    @memberships = []
    @error_msg = ''
    @success_msg = ''
  end

  def process(membership_ids)
    membership_ids.each do |id|
      membership = Membership.find(id.to_i)
      @memberships << membership unless membership.attendance == 'Confirmed'
    end
    check_for_errors
  end

  def send_invitations
    pause_membership_syncing unless @memberships.empty?
    @memberships.each do |membership|
      membership.person.member_import = true # skip validations on save
      if membership.attendance == 'Not Yet Invited'
        Invitation.new(membership: membership,
                       invited_by: @current_user.person.name).send_invite
        @invited << membership.person.name
      else
        invite = Invitation.where(membership: membership).last
        if invite.blank?
          Invitation.new(membership: membership,
                         invited_by: @current_user.person.name).send_invite
          @invited << membership.person.name
        else
          invite.invited_by = @current_user.person.name
          invite.send_reminder
          @reminded << membership.person.name
        end
      end
    end
    add_success_message
  end

  def add_success_message
    @success_msg = ''
    @success_msg << "Invitations " and fill_msg(@invited) unless @invited.empty?
    @success_msg << "<br>\n" unless @success_msg.empty?
    @success_msg << " Reminders " and fill_msg(@reminded) unless @reminded.empty?
  end

  def fill_msg(names)
    @success_msg << "were sent to #{names.size} participants"
    if names.size > 3
      @success_msg << "."
    else
      @success_msg << ": "
      last_person = names.pop
      names.each {|p| @success_msg << "#{p}, " }
      @success_msg << "#{last_person}."
    end
    @success_msg
  end

  def check_for_errors
    @error_msg = 'No members selected to invite.' and return if @memberships.empty?
    @error_msg = max_participants_exceeded?
  end

  def max_participants_exceeded?
    msg = ''
    msg = max_hybrid_msg if @event.hybrid?

    msg = "You may not invite more than #{max_participants}
      participants.".squish if !@event.hybrid? && max_participants?

    msg << " You may not invite more than #{@event.max_observers}
      observers.".squish if max_observers?

    msg
  end

  def max_hybrid_msg
    msg = ''
    invited_physical = @memberships.count do |m|
        m.attendance == 'Not Yet Invited' && m.role == 'Participant'
    end
    if @event.num_invited_in_person + invited_physical > @event.max_participants
      msg = "You may not invite more than #{@event.max_participants}
                    in-person participants.".squish
    end

    invited_virtual = @memberships.count do |m|
      m.attendance == 'Not Yet Invited' && m.role == 'Virtual Participant'
    end

    if @event.num_invited_virtual + invited_virtual > @event.max_virtual
      msg << " You may not invite more than #{@event.max_virtual} virtual
            participants.".squish
    end
    msg
  end

  def max_participants
    @event.online? ? @event.max_virtual : @event.max_participants
  end

  def max_participants?
    invited = @memberships.count { |m| m.attendance == 'Not Yet Invited' &&
      m.role != 'Observer' }

    @event.num_invited_participants + invited > max_participants
  end

  def max_observers?
    invited_observers = @memberships.count { |m| m.role == 'Observer' &&
      m.attendance == 'Not Yet Invited' }
    return false if invited_observers == 0
    @event.num_invited_observers + invited_observers > @event.max_observers
  end

  private

  def pause_membership_syncing
    @event.sync_time = DateTime.now
    @event.save
  end
end
