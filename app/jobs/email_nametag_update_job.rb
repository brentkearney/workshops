# app/jobs/email_nametag_update_job.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Initiates StaffMailer for nametag problem
class EmailNametagUpdateJob < ApplicationJob
  queue_as :urgent

  def perform(event_code, params)
    event = Event.find(event_code)
    StaffMailer.nametag_update(event, args: params).deliver_now
  end
end
