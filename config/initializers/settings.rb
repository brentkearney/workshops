# Sets up some defaults to populate the Settings section
Rails.cache.delete('settings')

if Setting.find_by_var('Site').nil?
  s = Setting.new(var: 'Site', value: {
    'title': 'Workshop Manager',
    'logo': 'logo.png',
    'footer': 'Copyright © 2016 Example Organization',
    'events_url': 'http://www.example.com/events',
    'legacy_api': 'https://database.example.com/api/your_api_key',
    'legacy_person': 'https://www.example.com/db/?section=Updates&sub=person&id=',
    'application_email': 'workshops@example.com',
    'webmaster_email': 'webmaster@example.com',
    'sysadmin_email': 'sysadmin@example.com',
    'event_types': ['5 Day Workshop', '2 Day Workshop', 'Research in Teams',
    'Focussed Research Group', 'Summer School', 'Public Lecture'],
    'code_pattern': '\A\d{2}(w|ss|rit|frg|pl)\d{3,4}\z'
  })
  s.save!
end

if Setting.find_by_var('Emails').nil?
  s = Setting.new(var: 'Emails', value: {
    :EO => {
      'program_coordinator': 'organization@example.com',
      'secretary': 'organization-secretary@example.com',
      'administrator': 'organization-administrator@example.com',
      'director': 'organization-director@example.com',
      'videos': 'videos@example.com',
      'schedule_staff': 'barista@example.com, photographer@example.com',
      'event_updates': 'webmaster@example.com, communications@example.com',
      'name_tags': 'organization-secretary@example.com'
    }
  })
  s.save!
end

if Setting.find_by_var('Locations').nil?
  s = Setting.new(var: 'Locations', value: {
    :EO => {
      'Name': 'Example Organization',
      'Country': 'Canada',
      'Timezone': 'Mountain Time (US & Canada)'
    }
  })
  s.save!
end

if Setting.find_by_var('Rooms').nil?
  s = Setting.new(var: 'Rooms', value: {
    :EO => {
      '5 Day Workshop': 'TCPL 201',
      '2 Day Workshop': 'TCPL 201',
      'Summer School':  'TCPL 202',
      'Focussed Research Group':  'TCPL 202',
      'Research in Teams': 'TCPL 107',
      'Contact Organizer': 'CH2',
      'Organizer': 'CH2',
      'Participant': 'CH1',
      'CH1': ['5112', '5114', '5120', '5122'],
      'CH2': ['5116', '5124']
    }
  })
  s.save!
end
