# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Wrapper class for accessing Settings variables more reliably
class GetSetting
  def self.site_setting(setting_string)
    settings_hash = Setting.Site
    not_set = "#{setting_string} not set"
    return not_set if settings_hash.blank?
    return not_set unless settings_hash.key? setting_string
    setting = settings_hash[setting_string]
    setting.blank? ? not_set : setting
  end

  def self.location(location, setting)
    return '' if location.blank?
    settings_hash = Setting.Locations[location]
    return '' if settings_hash[setting].blank?
    settings_hash[setting]
  end

  def self.no_setting(setting_string)
    parts = setting_string.scan(/\w+-?\w*/) # include hyphenated words
    settings_hash = Setting.send(parts[0]) # i.e. Locations
    return true if settings_hash.blank?
    location = parts[1]
    return true unless settings_hash.key? location # i.e. ['BIRS']
    field = parts[2]
    return true unless settings_hash[location].key? field # i.e. 'Country'
    return true if settings_hash[location][field].blank?
  end

  def self.schedule_lock_time(location)
    if no_setting("Locations['#{location}']['lock_staff_schedule']")
      return 7.days
    end

    Setting.Locations[location]['lock_staff_schedule'].to_duration
  end

  def self.rsvp_email(location)
    return ENV['DEVISE_EMAIL'] if no_setting("Emails['#{location}']['rsvp']")
    [Setting.Emails[location]['rsvp_from_email'],
      Setting.Emails[location]['rsvp_from_name']]
  end

  def self.org_name(location)
    return location if no_setting("Locations['#{location}']['Name']")
    Setting.Locations[location]['Name']
  end

  def self.billing_code(location, country)
    return '' if no_setting("Locations['#{location}']['billing_codes']")
    billing = eval(Setting.Locations[location]['billing_codes'])[country]
    billing || eval(Setting.Locations[location]['billing_codes'])['default']
  end

  def self.max_participants(location)
    return 42 if location.blank? ||
                 no_setting("Locations['#{location}']['max_participants']")
    Setting.Locations[location]['max_participants']
  end

  def self.max_observers(location)
    return 0 if location.blank? ||
                no_setting("Locations['#{location}']['max_observers']")
    Setting.Locations[location]['max_observers']
  end

  def self.max_virtual(location)
    return 300 if location.blank? ||
                  no_setting("Locations['#{location}']['max_virtual']")
    Setting.Locations[location]['max_virtual']
  end

  def self.rsvp_dates_intro(location)
    return false if no_setting("RSVP['#{location}']['arrival_departure_intro']")
    Setting.RSVP[location]['arrival_departure_intro']
  end

  def self.rsvp_accommodation_intro(location)
    return false if no_setting("RSVP['#{location}']['accommodation_intro']")
    Setting.RSVP[location]['accommodation_intro']
  end

  def self.rsvp_guests_intro(location)
    return false if no_setting("RSVP['#{location}']['guests_intro']")
    Setting.RSVP[location]['guests_intro']
  end

  def self.rsvp_has_guest(location)
    return false if no_setting("RSVP['#{location}']['has_guest']")
    Setting.RSVP[location]['has_guest']
  end

  def self.rsvp_guest_disclaimer(location)
    return false if no_setting("RSVP['#{location}']['guest_disclaimer']")
    Setting.RSVP[location]['guest_disclaimer']
  end

  def self.rsvp_special_intro(location)
    return false if no_setting("RSVP['#{location}']['special_intro']")
    Setting.RSVP[location]['special_intro']
  end

  def self.rsvp_personal_info_intro(location)
    return false if no_setting("RSVP['#{location}']['personal_info_intro']")
    Setting.RSVP[location]['personal_info_intro']
  end

  def self.rsvp_biography_intro(location)
    return false if no_setting("RSVP['#{location}']['biography_intro']")
    Setting.RSVP[location]['biography_intro']
  end

  def self.rsvp_privacy_notice(location)
    return false if no_setting("RSVP['#{location}']['privacy_notice']")
    Setting.RSVP[location]['privacy_notice']
  end

  def self.code_pattern
    pattern = site_setting('code_pattern')
    return '.+' if pattern == 'code_pattern not set'
    pattern
  end

  def self.events_url
    fallback = 'http://' + ENV['APPLICATION_HOST'] + '/events/'
    url = site_setting('events_url')
    return fallback if url == 'events_url not set'
    url
  end

  def self.app_url
    fallback = 'http://' + ENV['APPLICATION_HOST']
    url = site_setting('app_url')
    return fallback if url == 'app_url not set'
    url
  end

  def self.confirmation_lead_time(location)
    return 2.weeks if no_setting("Emails['#{location}']['confirmation_lead']")
    lead_time = Setting.Emails[location]['confirmation_lead']
    return 2.weeks if lead_time.blank?
    parts = lead_time.split('.')
    parts.first.to_i.send(parts.last)
  end

  def self.location_address(location)
    return '' if no_setting("Locations['#{location}']['Address']")
    Setting.Locations[location]['Address']
  end

  def self.location_country(location)
    return 'Unknown' if no_setting("Locations['#{location}']['Country']")
    Setting.Locations[location]['Country']
  end

  def self.default_location
    Setting.Locations.first.first
  end

  def self.locations
    Setting.Locations.keys
  end

  def self.new_registration_msg
    setting = Setting.Site['new_registration_msg']
    setting.blank? ? 'Site Setting "new_registration_msg" is missing.' : setting
  end

  def self.about_invitations_msg
    setting = Setting.Site['about_invitations_msg']
    setting.blank? ? 'Site Setting "about_invitations_msg" is missing.' : setting
  end

  def self.default_timezone
    Setting.Locations.first.second['Timezone']
  end

  # Emails set in Settings.Site
  def self.site_email(email_setting)
    email = site_setting(email_setting)
    return ENV['DEVISE_EMAIL'] if email == "#{email_setting} not set"
    email
  end

  # Emails set in Settings.Emails
  def self.email(location, email_setting)
    if no_setting("Emails['#{location}']['#{email_setting}']")
      return ENV['DEVISE_EMAIL']
    end
    Setting.Emails[location][email_setting]
  end
end
