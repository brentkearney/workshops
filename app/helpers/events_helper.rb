# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module EventsHelper

  def get_text(field)
    if field.blank?
      field = ''
      if policy(@event).edit?
        field << %q( Please set one by clicking the "Edit Event" button! )
      else
        field = 'No description is set.'
      end
    else
      field = simple_format(field).gsub(/<br><br>/, '').html_safe
    end
    field
  end

  def event_list_title
    title = ''
    case request.path
    when '/events'
      title = 'All'
    when /events\/my_events/
      title = 'My'
    when /future|past/
      time = request.path.match(/events\/(\w+)/)
      title = time[1].titleize
    when /year/
      year = request.path.match(/year\/(\w+)/)
      title = year[1]
    end
    title << " Events"

    location = request.path.match(/location\/(\w+)/)
    title[/Events/] = "#{location[1]} Events" unless location.blank?
    title
  end

  def location_url(location)
    case request.path
    when /past|future/
      '/events/' + action_name + "/location/#{location}"
    when /year/
      year = request.path.match(/year\/(\w+)/)
      "/events/year/#{year[1]}/location/#{location}"
    else
      events_location_path(location)
    end
  end

  def year_url(year)
    location = request.path.match(/location\/(\w+)/)
    if location.blank?
      events_year_path(year)
    else
      "/events/year/#{year}/location/#{location[1]}"
    end
  end
end
