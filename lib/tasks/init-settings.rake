# Copyright (c) 2016 Banff International Research Station
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be included in all copies
# or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

namespace :ws do
  task default: 'settings:print_options'

  # safe default
  task :print_options do
    puts "Run 'rake ws:init_settings' to add default Setttings, required for app to run."
  end

  desc "Add default settings"
  task init_settings: :environment do
    puts "Adding default Settings (where necessary)..."
    if Setting.find_by(var: 'Site').blank?
      puts "* Applying default Site settings"
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
        'rsvp_expiry' => '2.weeks'
      }
    end

    if Setting.find_by(var: 'Emails').blank?
      puts "* Applying default Emails settings"
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
          'confirmation_lead' => '1.year'
        }
      }
    end

    if Setting.find_by(var: 'Locations').blank?
      puts "* Applying default Locations settings"
      Setting.Locations = {
        'EO' => {
          'Name' => 'Example Organization',
          'Country' => 'Canada',
          'Timezone' => 'Mountain Time (US & Canada)',
          'Address' => "123 Example Street\nExampletown, Exampleton"
        }
      }
    end

    if Setting.find_by(var: 'Rooms').blank?
      puts "* Applying default Rooms settings"
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
      puts "* Applying default RSVP settings"
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
    puts "Done!\n"
  end
end
