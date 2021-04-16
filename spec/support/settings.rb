# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

#  Load default settings
require 'rails-settings-cached'

if Setting.find_by(var: 'Site').blank?
  Setting.Site = {
    'title' => 'Workshop Manager',
    'logo' => 'logo.png',
    'footer' => 'Copyright © 2016 Example Organzation',
    'events_url' => 'http://www.example.com/events/',
    'app_url' => 'http://workshops.example.com',
    'legacy_api' => 'https://database.example.com/api/your_api_key',
    'legacy_person' => 'https://www.example.com/db/?section=Updates&sub=person&id=',
    'application_email' => 'workshops@example.com',
    'webmaster_email' => 'webmaster@example.com',
    'sysadmin_email' => 'sysadmin@example.com',
    'event_types' => ['5 Day Workshop', '2 Day Workshop', 'Research in Teams', 'Focussed Research Group', 'Summer School', 'Public Lecture'],
    'code_pattern' => '\A\d{2}(w|ss|rit|frg|pl)\d{3,4}\z',
    'academic_status' => ['Professor', 'Post Doctoral Fellow', 'Medical Doctor', 'Ph.D. Student', 'Masters Student', 'Undergraduate Student', 'K-12 Teacher', 'K-12 Student', 'Other'],
    'salutations' => ['Prof.', 'Dr.', 'Mr.', 'Mrs.', 'Miss', 'Ms.'],
    'event_formats' => ['Physical', 'Online', 'Hybrid'],
    'rsvp_expiry' => '1.month',
    'email_domain' => 'workshops.example.com',
    'maillist_domain' => 'lists.example.com',
    'recording_api' => 'http://localhost:666',
    'LECTURES_API_KEY' => '0123456789',
    'EVENTS_API_KEY' => '0123456789',
    'SPARKPOST_AUTH_TOKEN' => '1234',
    'grant_list' => [
      ["1501 - Genes, Cells and Molecules", "NSERC:1501"],
      ["1502 - Biological Systems and Functions", "NSERC:1502"],
      ["1503 - Evolution and Ecology", "NSERC:1503"],
      ["1504 - Chemistry", "NSERC:1504"],
      ["1505 - Physics", "NSERC:1505"],
      ["1506 - Geosciences", "NSERC:1506"],
      ["1507 - Computer Science", "NSERC:1507"],
      ["1508 - Mathematics and Statistics", "NSERC:1508"],
      ["1509 - Civil, Industrial and Systems Engineering", "NSERC:1509"],
      ["1510 - Electrical and Computer Engineering", "NSERC:1510"],
      ["1511 - Materials and Chemical Engineering", "NSERC:1511"],
      ["1512 - Mechanical Engineering", "NSERC:1512"],
      ["CIHR grant", "CIHR"],
      ["SSHRC grant", "SSHRC"]
    ]
  }
end

if Setting.find_by(var: 'Emails').blank?
  Setting.Emails = {
    'EO' => {
      'program_coordinator' => 'organization@example.com',
      'secretary' => 'organization-secretary@example.com',
      'administrator' => 'organization-administrator@example.com',
      'director' => 'organization-director@example.com',
      'videos' => 'videos@example.com',
      'schedule_staff' => 'barista@example.com, photographer@example.com',
      'event_updates' => 'webmaster@example.com, communications@example.com',
      'name_tags' => 'organization-secretary@example.com',
      'confirmation_notices' => 'organization@example.com',
      'rsvp' => 'rsvp@example.com',
      'station_manager' => 'stnmgr@example.com',
      'confirmation_lead' => '1.year',
      'maillist_from' => '"Workshops Maillist" <no-reply@example.com>',
      'email_domain' => 'example.com',
      'rsvp_email' => 'coordinator@example.com'
    }
  }
end

# if Setting.find_by(var: 'Locations').blank?
  Setting.Locations = {
    'EO' => {
      'Name' => 'Example Organization',
      'Country' => 'Canada',
      'Timezone' => 'Mountain Time (US & Canada)',
      'Address' => "123 Example Street\nExampletown, Exampleton",
      'lock_staff_schedule' => '15.days',
      'max_participants' => 42,
      'max_virtual' => 300,
      'max_observers' => 5,
      'billing_codes' => "{'default' => 'EO1', 'USA' => 'EO2'}"
    }
  }
# end

if Setting.find_by(var: 'Rooms').blank?
  Setting.Rooms = {
    'EO' => {
      '5 Day Workshop' => 'TCPL 201',
      '2 Day Workshop' => 'TCPL 201',
      'Summer School' =>  'TCPL 202',
      'Focussed Research Group' =>  'TCPL 202',
      'Research in Teams' => 'TCPL 107',
      'Contact Organization' => 'CH2',
      'Organization' => 'CH2',
      'Participant' => 'CH1',
      'CH1' => ['5112', '5114', '5120', '5122'],
      'CH2' => ['5116', '5124']
    }
  }
end

if Setting.find_by(var: 'RSVP').blank?
  Setting.RSVP = {
    'EO' => {
      'arrival_departure_intro' => "If you plan to arrive after the event starts, or to leave before it ends, please indicate when by clicking the days on the calendars below. If you plan to book your own accommodation instead, please check the box below the calendars.",
      'guests_intro' => "If you wish to bring a guest, please select the checkbox below.",
      'has_guest' => "I plan to bring a guest with me.",
      'guest_disclaimer' => "I am aware that I may have to pay extra for my guest's accommodation.",
      'special_intro' => "Please let us know if you have any special dietary or other needs.",
      'personal_info_intro' => "",
      'privacy_notice' => "We promise not to share your information with anyone."
    }
  }
end
