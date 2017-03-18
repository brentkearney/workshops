# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module RsvpHelper

  # options for select menu
  def future_events_options
    options = []
    @events.each do |e|
      name = e.name.truncate(60, omission: '...')
      options << ["#{e.date}: [#{e.code}] #{name}", e.code]
    end
    options
  end
end
