# app/forms/invite_members_form.rb
#
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# For views/memberships/invite.html.erb
class InviteMembersForm < ComplexForms
  attr_accessor :invited, :new_people, :role, :sync_errors

  include Syncable

  def initialize(event, current_user)
    @event = event
    @current_user = current_user
    @sync_errors = ErrorReport.new(self.class, @event)
    self.invited = []
    self.new_people = []
    self.role = 'Participant'
  end

  def process(membership_ids)
    Rails.logger.debug "\n\n.process received: #{membership_ids}\n\n"
    membership_ids.each do |id|
      m = Membership.find(id.to_i)
      Rails.logger.debug "\t* #{m.person.name} (#{m.attendance})\n"
    end
  end
end
