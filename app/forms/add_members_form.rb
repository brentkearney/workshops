# app/forms/add_members_form.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# For views/memberships/add.html.erb
class AddMembersForm < ComplexForms
  def initialize(event)
    @event = event
  end
end
