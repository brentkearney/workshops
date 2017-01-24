# Sets up some defaults to populate the Settings section

if Setting.Site.blank?
  Setting.Site = {
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
  }
end

if Setting.Emails.blank?
  Setting.Emails = {
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
  }
end

if Setting.Locations.blank?
  Setting.Locations = {
    :EO => {
      'Name': 'Example Organization',
      'Address': '123 Example Street',
      'City': 'Exampletown',
      'Region': 'EX',
      'Postal Code': '1E2 3X4',
      'Country': 'Canada',
      'Timezone': 'Mountain Time (US & Canada)',
      'Description': 'Please edit this example organization in Settings.'
    }
  }
end

if Setting.Rooms.blank?
  Setting.Rooms = {
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
  }
end
