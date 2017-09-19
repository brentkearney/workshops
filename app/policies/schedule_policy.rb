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

  # permission to change the staff_item field
  def update_staff_item?
    staff_or_admin
  end

  def update?
    staff_or_admin || (event_organizer && within_lock_staff_schedule)
  end

  def edit_staff_items?
    staff_or_admin
  end

  def create?
    event_organizer || staff_or_admin
  end

  # Only organizers and admins can change event schedules
  def method_missing(name, *args)
    if name =~ /index|show/
      true
    else
      event_organizer || staff_or_admin
    end
  end

  def within_lock_staff_schedule
    return true unless @schedule.staff_item
    Date.current + Setting.Locations[@event.location]['lock_staff_schedule']
                   .to_duration < @event.start_date
  end

  def event_organizer
    return false unless @current_user
    @current_user.is_organizer?(@event)
  end

  def staff_or_admin
    return false unless @current_user
    @current_user.is_admin? ||
      (@current_user.is_staff? && @current_user.location == @event.location)
  end
end
