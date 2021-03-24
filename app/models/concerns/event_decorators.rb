# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module EventDecorators
  extend ActiveSupport::Concern

  def year
    start_date.strftime('%Y')
  end

  def days
    day = start_date.to_time.in_time_zone(time_zone).beginning_of_day
    days = [day]
    # Compare date strings so TZ issues don't interfere
    end_of_ws = end_date.to_time.in_time_zone(time_zone).end_of_day
    datestring = end_of_ws.strftime('%Y%m%d').to_s
    until day.strftime('%Y%m%d').to_s == datestring
      day += 1.day
      days << day
    end
    days
  end

  def num_participants
    memberships.size
  end

  def num_invited_in_person
    memberships.where("(attendance = 'Invited' OR attendance = 'Undecided'
      OR attendance = 'Confirmed') AND role != 'Observer'
      AND (role = 'Participant' OR role LIKE '%Organizer')
      AND role != 'Virtual%'").size
  end

  def num_invited_virtual
    memberships.where("(attendance = 'Invited' OR attendance = 'Undecided'
      OR attendance = 'Confirmed') AND role != 'Observer'
      AND role LIKE 'Virtual%'").size
  end

  def num_invited_participants
    memberships.where("(attendance = 'Invited' OR attendance = 'Undecided'
      OR attendance = 'Confirmed') AND role != 'Observer'").size
  end

  def num_invited_observers
    memberships.where("(attendance = 'Invited' OR attendance = 'Undecided'
      OR attendance = 'Confirmed') AND role = 'Observer'").size
  end

  def attendance(status = 'Confirmed', order = 'lastname')
    direction = 'ASC'

    # We want the order to be the same as the order of Membership::ROLES
    all_members = memberships.joins(:person).where('attendance = ?', status)
                             .order(order + " " + direction)
    sorted_members = []
    Membership::ROLES.each do |role|
      sorted_members.concat(all_members.select { |member| member.role == role })
    end
    sorted_members
  end

  def role(role = 'Participant', order = 'lastname')
    memberships.joins(:person).where('role = ?', role).order(order)
  end

  def num_attendance(status)
    attendance(status).size
  end

  def attendance?(status)
    num_attendance(status) > 0
  end

  def member_info(person)
    person_profile = {}
    person_profile['firstname'] = person.firstname
    person_profile['lastname'] = person.lastname
    person_profile['affiliation'] = person.affiliation
    person_profile['url'] = person.uri
    person_profile
  end

  def dates(format = :short)
    start = Date.parse(start_date.to_s)
    finish = Date.parse(end_date.to_s)

    d = format == :long ? start.strftime('%B %-d') : start.strftime('%b %-d')
    d += ' - '

    if start.mon == finish.mon
      d += format == :long ? finish.strftime('%-d, %Y') : finish.strftime('%-d')
    else
      d += format == :long ? finish.strftime('%B %-d, %Y') : finish.strftime('%b %-d')
    end
    d
  end

  def arrival_date
    start_date.strftime('%A, %B %-d, %Y')
  end

  def departure_date
    end_date.strftime('%A, %B %-d, %Y')
  end

  def date
    start_date.strftime('%Y-%m-%d')
  end

  def address
    GetSetting.location_address(self.location)
  end

  def country
    GetSetting.location_country(self.location)
  end

  def organizer
    membership = memberships.where(role: 'Contact Organizer').last
    membership.blank? ? Person.new(email: '') : membership.person
  end

  def organizers
    memberships.where("role LIKE '%Organizer%'").map {|m| m.person }
  end

  def contact_organizers
    organizers = []
    memberships.where(role: 'Contact Organizer').each do |org_member|
      organizers << org_member.person
    end
    organizers
  end

  def supporting_organizers
    organizers = []
    memberships.where(role: 'Organizer').each do |org_member|
      organizers << org_member.person
    end
    organizers
  end

  def staff
    staff = User.where(role: :staff, location: self.location).map {|s| s.person }
    admins = User.where('role > 1').map {|a| a.person }
    staff + admins
  end

  def schedule_on(day)
    schedules.select { |s| s.start_time.to_date == day.to_date }
             .sort_by(&:start_time)
  end

  def confirmed
    people = memberships.where(attendance: 'Confirmed').map {|m| m.person }
    people.sort_by { |p| p.lastname.downcase }
  end

  def current?
    Time.current >= DateTime.parse(start_date.to_s) && Time.current <=
      DateTime.parse(end_date.to_s).change(hour: 23, min: 59)
  end

  def upcoming?
    Time.current <= DateTime.parse(start_date.to_s)
  end

  def past?
    DateTime.parse(end_date.to_s) < Time.current
  end

  def url
    event_url = GetSetting.events_url
    event_url << '/' if event_url[-1] != '/'
    event_url + code
  end

  def options_list
    "#{self.date}: [#{self.code}] #{self.name}".truncate(55)
  end

  def append_name(word)
    self.name << " (#{word})" unless self.name.include?("(#{word})")
  end

  def truncate_name(word)
    self.name.gsub!("(#{word})", "").strip! if self.name.include?("(#{word})")
  end

  def update_name
    append_name('Cancelled') if self.cancelled
    truncate_name('Cancelled') unless self.cancelled

    append_name('Online') if self.event_format == 'Online'
    truncate_name('Online') unless self.event_format == 'Online'
  end

  def online?
    self.event_format == 'Online'
  end

  def hybrid?
    self.event_format == 'Hybrid'
  end

  def physical?
    self.event_format == 'Physical'
  end
end
