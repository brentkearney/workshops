# app/jobs/event_email_update_job.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Initiates StaffMailer to confirm RSVPs
class EmailEventUpdateJob < ApplicationJob
  queue_as :urgent

  def perform(event_code, params)
    event = Event.find(event_code)
    StaffMailer.event_update(event, args: params).deliver_now
  end
end
