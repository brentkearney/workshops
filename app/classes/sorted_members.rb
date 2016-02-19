# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class SortedMembers
  attr_reader :event, :memberships

  def initialize(event)
    @event = event
    @memberships = {}
  end

  def memberships
    get_members_hash && sort_by_attendance && sort_by_role_and_name
  end

  def get_members_hash
    @event.memberships.includes(:person).each do |m|
      if @memberships.has_key? m.attendance
        @memberships["#{m.attendance}"] << m
      else
        @memberships["#{m.attendance}"] = [m]
      end
    end
    @memberships
  end

  def sort_by_attendance
    sorted = {}
    Membership::ATTENDANCE.each do |status|
      if @memberships.has_key? status
        sorted["#{status}"] = @memberships["#{status}"]
      end
    end
    @memberships = sorted
  end

  def sort_by_role_and_name
    sorted = {}
    @memberships.each do |status, members|
      sorted["#{status}"] = []
      Membership::ROLES.each do |role|
        members.select {|m| m.role == role}.sort_by {|m| m.person.lastname }.each do |member|
          sorted["#{status}"] << member
        end
      end
    end
    @memberships = sorted
  end

end