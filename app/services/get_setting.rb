# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Wrapper class for accessing Settings variables more reliably
class GetSetting
  def self.schedule_lock_time(event)
    location = event.location
    if no_setting("Setting.Locations['#{location}']['lock_staff_schedule']")
      return 7.days
    end

    Setting.Locations[location]['lock_staff_schedule'].to_duration
  end

  def self.no_setting(setting_string)
    parts = setting_string.scan(/\w+/)
    parts.shift
    settings_hash = Setting.send(parts[0]) # Locations
    return true if settings_hash.blank?
    return true unless settings_hash.key? parts[1] # Locations['BIRS']
    return true unless settings_hash[parts[1]].key? parts[2] # 'lock_staff...
  end
end
