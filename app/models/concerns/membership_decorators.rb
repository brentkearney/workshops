# Copyright (c) 2020 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module MembershipDecorators
  extend ActiveSupport::Concern

  def shares_email?
    self.share_email
  end

  def organizer?
    role == 'Organizer' || role == 'Contact Organizer'
  end

  def arrives
    return 'Not set' if arrival_date.blank?
    arrival_date.strftime('%b %-d, %Y')
  end

  def departs
    return 'Not set' if departure_date.blank?
    departure_date.strftime('%b %-d, %Y')
  end

  def rsvp_date
    return 'N/A' if replied_at.blank?
    replied_at.in_time_zone(event.time_zone).strftime('%b %-d, %Y %H:%M %Z')
  end

  def last_updated
    updated_at.in_time_zone(event.time_zone).strftime('%b %-d, %Y %H:%M %Z')
  end

  def confirmed?
    attendance == 'Confirmed'
  end

  def declined?
    attendance == 'Declined'
  end

  def undecided?
    attendance == 'Undecided'
  end

  def invited?
    attendance == 'Invited'
  end
end
