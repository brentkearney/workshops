# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class Setting < RailsSettings::Base
  validates :var, uniqueness: true
  namespace Rails.env

  def name(key)
    loc = Setting.find_by_var('Locations').value[key.to_sym]
    loc.nil? ? key : loc['Name']
  end
end
