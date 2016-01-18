# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module EventsHelper

  def get_description
    if @event.description.blank?
      description = 'No description is set.'
      if user_is_organizer?
        description << %q( Please set one by clicking the "Edit Event" button!)
      end
      return description
    else
      @event.description.html_safe
    end
  end
end
