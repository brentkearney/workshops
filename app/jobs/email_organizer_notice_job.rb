# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Initiates OrganizerMailer to notify of RSVPs
class EmailOrganizerNoticeJob < ActiveJob::Base
  queue_as :urgent

  rescue_from(SparkPostRails::DeliveryException) do |exception|
    membership_id = arguments[0]
    membership = Membership.find_by_id(membership_id)
    person = membership.person
    event = membership.event
    msg = { error: "Error sending RSVP notice to #{event.code} Organizer for
                   #{person.name} RSVP".squish,
            exception: exception }
    StaffMailer.notify_sysadmin(nil, msg).deliver_now
  end

  def perform(membership_id, args)
    membership = Membership.find_by_id(membership_id)
    OrganizerMailer.rsvp_notice(membership, args).deliver_now
  end
end
