# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Authorization for Schedules
class SchedulePolicy
  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @schedule = model.nil? ? Schedule.new : model
    @event = @schedule.event
  end

  def create?
    return false unless @current_user
    @current_user.is_organizer?(@event) || @current_user.is_admin? ||
      (@current_user.is_staff? && @current_user.location == @event.location)
  end

  # Only organizers and admins can change event schedules
  def method_missing(name, *args)
    if name =~ /index|show/
      true
    else
      return false unless @current_user
      @current_user.is_organizer?(@event) || @current_user.is_admin? ||
        (@current_user.is_staff? && @current_user.location == @event.location)
    end
  end
end
