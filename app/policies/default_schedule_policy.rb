# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Authorization for creating default schedules
class DefaultSchedulePolicy
  attr_reader :user, :schedule, :event

  def initialize(user, schedule)
    @user = user
    @schedule = schedule
    @event = schedule.event
  end

  def allow?
    return false if user.nil?
    user.is_organizer?(event) || user.is_admin? ||
      (user.is_staff? && user.location == event.location)
  end
end
