# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module EventDecorators
  extend ActiveSupport::Concern

  def days
    day = start_date.to_time.noon
    days = [day]
    # Compare date strings so TZ issues don't interfere
    until "#{day.strftime("%Y%m%d")}" == "#{end_date.to_time.strftime("%Y%m%d")}"
      day = day + 1.day
      days << day
    end
    days
  end

  def num_participants
    memberships.size
  end

  def num_invited_participants
    memberships.where("(attendance = 'Invited' OR attendance = 'Undecided' OR attendance = 'Confirmed') AND role != 'Observer'").size
  end

  def attendance(status='Confirmed', order='lastname')
    direction = 'ASC'

    # We want the order to be the same as the order of Membership::ROLES
    all_members = memberships.joins(:person).where("attendance = ?", status).order("#{order} #{direction}")
    sorted_members = []
    Membership::ROLES.each do |role|
      sorted_members.concat(all_members.select { |member| member.role == role })
    end
    sorted_members
  end

  def num_attendance(status)
    self.attendance(status).size
  end

  def has_attendance(status)
    self.num_attendance(status) > 0
  end

  def organizers
    organizers = []
    memberships.joins(:person).where("role LIKE '%Org%'").order("role ASC, lastname").each do |member|
      p = member.person
      organizer = {}
      organizer['firstname'] = p.firstname
      organizer['lastname'] = p.lastname
      organizer['affiliation'] = p.affiliation
      organizer['url'] = p.url
      organizers.push(organizer)
    end
    organizers
  end

  def dates(format = 'short')
    start = Date.parse(start_date.to_s)
    finish = Date.parse(end_date.to_s)

    if format == 'long'
      ld = start.strftime("%B %-d")
    else
      ld = start.strftime("%b %-d")
    end

    ld += " - "

    if start.mon == finish.mon
      if format == 'long'
        ld += finish.strftime("%-d, %Y")
      else
        ld += finish.strftime("%-d")
      end
    else
      if format == 'long'
        ld += finish.strftime("%B %-d, %Y")
      else
        ld += finish.strftime("%b %-d")
      end
    end
  end

  def arrival_date
    start_date.strftime("%A, %B %-d, %Y")
  end

  def departure_date
    end_date.strftime("%A, %B %-d, %Y")
  end

  def country
    if Global.location.country.key?(self.location)
      Global.location.country.send(self.location)
    end
  end

  def schedule_on(day)
    schedules.select {|s| s.start_time.to_date == day.to_date }.sort_by(&:start_time)
  end

  def confirmed
    people = Array.new
    memberships.where(attendance: 'Confirmed').each do |m|
      people << m.person
    end
    people.sort_by {|p| p.lastname.downcase}
  end

  def is_current?
    Time.now >= start_date.to_time && Time.now <= end_date.to_time.change({ hour: 23, min: 59})
  end

end