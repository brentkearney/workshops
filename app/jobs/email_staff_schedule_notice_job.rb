# app/jobs/email_staff_schedule_notice_job.rb
#
# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Initiates StaffMailer to notify of schedule changes
class EmailStaffScheduleNoticeJob < ApplicationJob
  queue_as :urgent

  def perform(event_id, message)
    StaffMailer.schedule_change(event_id: event_id,
                                message: message).deliver_now
  end
end
