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
        'academic_status' => ["Professor Emeritus", "Professor", "Associate Professor", "Assistant Professor",
                              "Post Doctoral Fellow", "Medical Doctor", "Ph.D. Student", "Masters Student",
                              "Undergraduate Student", "K-12 Teacher", "K-12 Student", "Other"],
        'salutations' => ['Prof.', 'Dr.', 'Mr.', 'Mrs.', 'Miss', 'Ms.'],
        'rsvp_expiry' => '2.weeks',
        'email_domain' => 'workshops.example.com',
        'LECTURES_API_KEY' => 'Example-ChangeMe',
        'EVENTS_API_KEY' => 'Example-ChangeMe',
        'SPARKPOST_AUTH_TOKEN' => 'Example-ChangeMe',
        'new_registration_msg' => '<h2>About Workshop Participation</h2> <p>To attend an Example Organization workshop, you must be invited by the organizers of the workshop.  If you have been invited, note the e-mail address to which the invitation was sent. This is the e-mail address that identifies you in our database, and must be used to register an account here. Only invited participants may  register.</p> <p>If you have not been invited to a workshop, please see   <a href="#">these guidelines</a>.</p>',
        'about_invitations_msg' => '<h2>About Workshop Invitations</h2>  <p>This form is for requesting <em>another</em> invitation to a workshop that you have already been invited to, by the workshop organizers. Note the  e-mail address to which the invitation was previously sent. This is the e-mail address that identifies you in our database, and must be used to request another invitation.</p>  <p>If you have not been invited to a workshop already, please see  <a href="#">these guidelines</a>.</p>'
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
          'station_manager' => 'stnmgr@example.com',
          'videos' => 'videos@example.com',
          'schedule_staff' => 'barista@example.com, photographer@example.com',
          'event_updates' => 'webmaster@example.com, communications@example.com',
          'name_tags' => 'organization-secretary@example.com',
          'confirmation_notices' => 'organization@example.com',
          'rsvp' => 'rsvp@example.com',
          'confirmation_lead' => '1.year',
          'maillist_from' => '"Workshops Maillist" <no-reply@example.com>',
          'email_domain' => 'example.com'
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
          'Address' => "123 Example Street\nExampletown, Exampleton",
          'lock_staff_schedule' => '15.days',
          'max_participants' => 42,
          'max_observers' => 2
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
