# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module EventsHelper

  def get_description
    if @event.description.blank?
      if policy(@event).event_staff?
        description << %q( Please set one by clicking the "Edit Event" button! )
      else
        description = 'No description is set.'
      end
    else
      simple_format(@event.description).gsub(/<br><br>/, '').html_safe
    end
  end
end
