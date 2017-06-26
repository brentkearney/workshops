# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Initiates StaffMailer to confirm RSVPs
class EmailScheduleChangeNoticeJob < ActiveJob::Base
  queue_as :urgent

  def perform(schedule_id, args)
    schedule = Schedule.find_by_id(schedule_id)
    StaffMailer.schedule_change(schedule, args).deliver_now
  end
end
