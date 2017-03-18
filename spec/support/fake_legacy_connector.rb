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

require 'factory_girl'

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

  def get_event_data(event_id)

  end

  def get_event_data_for_year(year)

  end

  def get_members(event)
    remote_members = []

    # Change the existing members and return them
    event.memberships.each do |m|
      remote_members << {
          'Workshop' => '#{event.code}',
          'Person' => {
              'lastname'=>m.person.lastname, 'firstname'=>m.person.firstname,
              'email'=>m.person.email, 'cc_email'=>nil,
              'gender'=>m.person.gender, 'affiliation'=>'New Affiliation',
              'salutation'=>nil, 'url'=>nil, 'phone'=>nil, 'fax'=>nil,
              'address1'=>m.person.address1, 'address2'=>nil, 'address3'=>nil,
              'city'=>nil, 'region'=>nil, 'country'=>nil, 'postal_code'=>nil,
              'academic_status'=>nil, 'department'=>nil, 'title'=>nil,
              'phd_year'=>nil, 'biography'=>nil, 'research_areas'=>nil,
              'updated_at'=>Time.now, 'legacy_id'=>m.person.legacy_id,
              'emergency_contact'=>nil, 'emergency_phone'=>nil,
              'updated_by'=>'FakeLegacyConnector'},
          'Membership'=> {
              'arrival_date'=>event.start_date + 1.day,
              'departure_date'=>event.end_date - 1.day,
              'attendance'=>m.attendance, 'role'=>m.role,
              'replied_at'=>m.replied_at, 'updated_by'=>'FakeLegacyConnector',
              'updated_at'=>Time.now}
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
      m['Membership']['updated_by'] = ''
      m['Membership']['updated_at'] = nil
      m['Membership']['role'] = 'Backup Participant'
      new_remote_members << m
    end
    new_remote_members
  end

  def get_members_with_person(e: event, m: membership, ln: lastname)
    if m.nil?
      person = Person.new(lastname: ln, firstname: 'NewPerson',
        email: 'newperson@new9000234.ca', affiliation: 'New Affil', gender: 'F')
      m = Membership.new(event: e, person: person, role: 'Participant',
                        replied_at: Time.now - 1.days, attendance: 'Confirmed')
    end

    remote_member = [{
        'Workshop' => '#{e.code}',
        'Person' => {
            'lastname' => ln, 'firstname'=>m.person.firstname,
            'email'=>m.person.email, 'cc_email'=>nil,
            'gender'=>m.person.gender, 'affiliation'=>m.person.affiliation,
            'salutation'=>nil, 'url'=>nil, 'phone'=>nil, 'fax'=>nil,
            'address1'=>m.person.address1, 'address2'=>nil, 'address3'=>nil,
            'city'=>nil, 'region'=>nil, 'country'=>nil, 'postal_code'=>nil,
            'academic_status'=>nil, 'department'=>nil, 'title'=>nil,
            'phd_year'=>nil, 'biography'=>nil, 'research_areas'=>nil,
            'updated_at'=>Time.now, 'legacy_id'=>m.person.legacy_id,
            'emergency_contact'=>nil, 'emergency_phone'=>nil,
            'updated_by'=>'FakeLegacyConnector'},
        'Membership'=> {
            'arrival_date'=>m.arrival_date, 'departure_date'=>m.departure_date,
            'attendance'=>m.attendance, 'role'=>m.role,
            'replied_at'=>m.replied_at, 'updated_by'=>'FakeLegacyConnector',
            'updated_at'=>Time.now, 'staff_notes'=>m.staff_notes}
    }]
  end

  def get_members_with_new_membership(e: event, p: person)
    m = Membership.new(event: e, person: p)
    remote_member = [{
         'Workshop' => '#{e.code}',
         'Person' => {
             'lastname' => p.lastname, 'firstname'=>p.firstname,
             'email'=>p.email, 'cc_email'=>nil,
             'gender'=>p.gender, 'affiliation'=>p.affiliation,
             'salutation'=>nil, 'url'=>nil, 'phone'=>nil, 'fax'=>nil,
             'address1'=>p.address1, 'address2'=>nil, 'address3'=>nil,
             'city'=>nil, 'region'=>nil, 'country'=>nil, 'postal_code'=>nil,
             'academic_status'=>nil, 'department'=>nil, 'title'=>nil,
             'phd_year'=>nil, 'biography'=>nil, 'research_areas'=>nil,
             'updated_at'=>Time.now, 'legacy_id'=>p.legacy_id,
             'emergency_contact'=>nil, 'emergency_phone'=>nil,
             'updated_by'=>'FakeLegacyConnector'},
         'Membership'=> {
             'arrival_date'=>m.arrival_date, 'departure_date'=>m.departure_date,
             'attendance'=>m.attendance, 'role'=>m.role,
             'replied_at'=>m.replied_at, 'updated_by'=>'FakeLegacyConnector',
             'updated_at'=>Time.now, 'staff_notes'=>m.staff_notes}
     }]
  end

  def get_members_with_changed_membership(m: membership, sn: staff_notes)

    remote_member = [{
     'Workshop' => '#{m.event.code}',
     'Person' => {
         'lastname' => m.person.lastname, 'firstname'=>m.person.firstname,
         'email'=>m.person.email, 'cc_email'=>nil, 'gender'=>m.person.gender,
         'affiliation'=>m.person.affiliation, 'salutation'=>nil, 'url'=>nil,
         'phone'=>nil, 'fax'=>nil, 'address1'=>m.person.address1,
         'address2'=>nil, 'address3'=>nil, 'city'=>nil, 'region'=>nil,
         'country'=>nil, 'postal_code'=>nil, 'academic_status'=>nil,
         'department'=>nil, 'title'=>nil, 'phd_year'=>nil, 'biography'=>nil,
         'research_areas'=>nil, 'updated_at'=>Time.now,
         'legacy_id'=>m.person.legacy_id, 'emergency_contact'=>nil,
         'emergency_phone'=>nil, 'updated_by'=>'FakeLegacyConnector'},
     'Membership'=> {
         'arrival_date'=>m.arrival_date, 'departure_date'=>m.departure_date,
         'attendance'=>m.attendance, 'role'=>m.role, 'replied_at'=>m.replied_at,
         'updated_by'=>'FakeLegacyConnector', 'updated_at'=>Time.now,
         'staff_notes'=>sn}
    }]
  end

  def get_person(legacy_id)

  end

  def search_person(email)

  end

  def add_person(person)

  end

  def add_member(membership, event_id, legacy_id, updated_by)

  end

  def add_members(event_id, members)

  end

  def update_member(membership, person, event_id, legacy_id, updated_by)

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

  end

  # successfull OTP validation
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
