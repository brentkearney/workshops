# Copyright (c) 2016 Banff International Research Station
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'factory_bot'

class FakeLegacyConnector
  def initialize
    Rails.logger.info "\n\n" + '*' * 50 + "\n\n"
    Rails.logger.info ' FakeLegacyConnector initialized '
    Rails.logger.info "\n" + '*' * 50 + "\n\n"
  end

  def list_events(from_date, to_date)
    if from_date !~ /\d/ || to_date !~ /\d/
      error_message = ["error", "Invalid years."]
      return [error_message]
    end

    if from_date.length == 4 && to_date.length == 4
      return ['14w5001', '15w5001']
    end
  end

  def search_person(email)
    Rails.logger.debug "search_person received email: #{email}\n"
    person = build(:person, email: email).attributes
    Rails.logger.debug "returning person: #{person.pretty_inspect}\n\n"
  end

  def replace_person(replace, replace_with)
  end

  def get_event_data(event_id)

  end

  def get_event_data_for_year(year)

  end

  def get_member(membership)
    {
      'Person' => membership.person.attributes.merge(
        updated_at: DateTime.current,
        research_areas: 'stuff'
      ),
      'Membership' => membership.attributes.merge(
        updated_at: DateTime.current,
        arrival_date: membership.event.start_date + 1.day,
        departure_date: membership.event.end_date - 1.day,
      )
    }
  end

  def get_members(event)
    remote_members = []

    # Change the existing members and return them
    event.memberships.each do |m|
      remote_members << {
          'Person' => {
              'lastname' => m.person.lastname, 'firstname' => m.person.firstname,
              'email' => m.person.email, 'cc_email' => nil,
              'gender' => m.person.gender, 'affiliation' => 'New Affiliation',
              'salutation' => nil, 'url' => nil, 'phone' => nil, 'fax' => nil,
              'address1' => m.person.address1, 'address2' => nil, 'address3' => nil,
              'city' => nil, 'region' => nil, 'country' => nil, 'postal_code' => nil,
              'academic_status' => nil, 'department' => nil, 'title' => nil,
              'phd_year' => nil, 'biography' => nil, 'research_areas' => nil,
              'updated_at' => Time.now, 'legacy_id' => m.person.legacy_id,
              'emergency_contact' => nil, 'emergency_phone' => nil,
              'updated_by' => 'FakeLegacyConnector'
          },
          'Membership' => {
              'arrival_date' => event.start_date + 1.day,
              'departure_date' => event.end_date - 1.day,
              'attendance' => m.attendance, 'role' => m.role,
              'replied_at' => m.replied_at, 'updated_by' => 'FakeLegacyConnector',
              'updated_at' => Time.now, 'billing' => 'BIRS', 'room' => 'CH1234',
              'reviewed' => true
          }
      }
    end

    remote_members
  end

  def get_members_with_changed_fields(event)
    remote_members = self.get_members(event)
    new_remote_members = []
    remote_members.each do |m|
      m['Person']['updated_by'] = ''
      m['Person']['updated_at'] = nil
      m['Person']['email'] = humanize_it(m['Person']['email'])
      m['Membership']['updated_by'] = ''
      m['Membership']['updated_at'] = nil
      m['Membership']['role'] = 'Backup Participant'
      m['Membership']['replied_at'] = '0000-00-00 00:00:00'
      new_remote_members << m
    end
    new_remote_members
  end

  def humanize_it(email)
    return if email.blank?
    ' ' + email.capitalize + ' '
  end

  def get_members_with_person(e: event, m: membership, changed_fields:)
    if m.nil?
      person_attributes = { lastname: 'Person', firstname: 'New',
                            email: 'newperson@newperson.ca', gender: 'F',
                            affiliation: 'New Affil',
                            legacy_id: 1234 }
      person = Person.new(person_attributes)
      m = Membership.new(event: e, person: person, role: 'Participant',
                        replied_at: Time.now - 1.days, attendance: 'Confirmed')
    end

    remote_person = {
          'lastname' => m.person.lastname, 'firstname' => m.person.firstname,
          'email' => m.person.email, 'cc_email' => nil,
          'gender' => m.person.gender, 'affiliation' => m.person.affiliation,
          'salutation' => nil, 'url' => nil, 'phone' => nil, 'fax' => nil,
          'address1' => m.person.address1, 'address2' => nil, 'address3' => nil,
          'city' => nil, 'region' => nil, 'country' => nil, 'title' => nil,
          'postal_code' => nil, 'academic_status' => nil, 'department' => nil,
          'phd_year' => nil, 'biography' => nil, 'research_areas' => nil,
          'updated_at' => Time.now, 'legacy_id' => m.person.legacy_id,
          'emergency_contact' => nil, 'emergency_phone' => nil,
          'updated_by' => 'FakeLegacyConnector'
        }
    remote_membership = {
          'arrival_date' => m.arrival_date, 'role' => m.role,
          'attendance' => m.attendance, 'departure_date' => m.departure_date,
          'replied_at' => m.replied_at, 'updated_by' => 'FakeLegacyConnector',
          'updated_at' => Time.now, 'staff_notes' => m.staff_notes,
          'reviewed' => true, 'room' => 'CH1234', 'billing' => 'OK'
        }

    if changed_fields.key?(:membership)
      changed_fields = changed_fields.delete(:membership)
      remote_membership = remote_membership.merge(changed_fields.stringify_keys)
    else
      remote_person = remote_person.merge(changed_fields.stringify_keys)
    end

    remote_member = [{
        'Person' => remote_person,
        'Membership' =>  remote_membership
    }]
  end

  def get_members_with_new_membership(e: event, p: person)
    m = Membership.new(event: e, person: p)
    [{
      'Person' => {
        'lastname' => p.lastname, 'firstname' => p.firstname,
        'email' => p.email, 'cc_email' => nil,
        'gender' => p.gender, 'affiliation' => p.affiliation,
        'salutation' => nil, 'url' => nil, 'phone' => nil, 'fax' => nil,
        'address1' => p.address1, 'address2' => nil, 'address3' => nil,
        'city' => nil, 'region' => nil, 'country' => nil,
        'academic_status' => nil, 'department' => nil, 'title' => nil,
        'phd_year' => nil, 'biography' => nil, 'research_areas' => nil,
        'updated_at' => Time.now, 'legacy_id' => p.legacy_id,
        'emergency_contact' => nil, 'emergency_phone' => nil,
        'updated_by' => 'FakeLegacyConnector', 'postal_code' => nil
      },
      'Membership' =>  {
        'arrival_date' => m.arrival_date, 'departure_date' => m.departure_date,
        'attendance' => m.attendance, 'role' => m.role,
        'replied_at' => m.replied_at, 'updated_by' => 'FakeLegacyConnector',
        'updated_at' => Time.now, 'staff_notes' => m.staff_notes,
        'reviewed' => true, 'room' => 'CH1234', 'billing' => 'OK'
      }
    }]
  end

  def get_members_with_changed_membership(m: membership, sn: staff_notes)
    [{
      'Person' => {
        'lastname' => m.person.lastname, 'firstname' => m.person.firstname,
        'email' => m.person.email, 'cc_email' => nil, 'salutation' => nil,
        'affiliation' => m.person.affiliation, 'gender' => m.person.gender,
        'phone' => nil, 'fax' => nil, 'address1' => m.person.address1,
        'address2' => nil, 'address3' => nil, 'city' => nil, 'region' => nil,
        'country' => nil, 'postal_code' => nil, 'academic_status' => nil,
        'department' => nil, 'title' => nil, 'phd_year' => nil, 'url' => nil,
        'research_areas' => nil, 'updated_at' => Time.now, 'biography' => nil,
        'legacy_id' => m.person.legacy_id, 'emergency_contact' => nil,
        'emergency_phone' => nil, 'updated_by' => 'FakeLegacyConnector'
      },
      'Membership' =>  {
        'arrival_date' => m.arrival_date, 'departure_date' => m.departure_date,
        'attendance' => m.attendance, 'role' => m.role,
        'replied_at' => m.replied_at, 'updated_by' => 'FakeLegacyConnector',
        'staff_notes' => sn, 'reviewed' => true, 'room' => 'CH1234',
        'billing' => 'OK', 'updated_at' => Time.now
      }
    }]
  end

  def exceed_max_participants(event, extras)
    require 'factory_bot_rails'
    remote_members = []
    (event.max_participants + extras).times do
      membership = FactoryBot.build(:membership, event: event)
      membership.person.updated_by = 'FakeLegacyConnector'
      membership.updated_by = 'FakeLegacyConnector'
      membership.attendance = 'Confirmed'
      remote_members << {
          'Person' => membership.person.attributes,
          'Membership' => membership.attributes
      }
    end
    remote_members
  end

  def get_person(legacy_id)

  end

  def search_person(email)

  end

  def add_person(person)

  end

  def add_member(membership:, event_code:, person:, updated_by:)

  end

  def add_members(event_code:, members:, updated_by:)

  end

  def update_member(membership)

  end


  def update_members(event_id, members)

  end

  def get_lectures(event_id)

  end

  def get_lecture(legacy_id)

  end

  def get_lecture_id(lecture)

  end

  def add_lecture(lecture)

  end

  def delete_lecture(lecture_id)

  end

  def send_lectures_report(event_id)

  end

  def check_rsvp(otp)
    { 'event_code' => Event.last.code }
  end

  # successful OTP validation
  def valid_otp
    message = {
      'otp_id' => 1,
      'legacy_id' => 2,
      'event_code' => '17w5001',
      'attendance' => 'Confirmed'
    }
  end

  def invalid_otp
    message = {
      'denied' => 'Invalid invitation code.'
    }
  end
end
