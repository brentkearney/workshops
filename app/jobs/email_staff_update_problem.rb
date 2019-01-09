# app/jobs/event_email_update_job.rb
#
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Initiates StaffMailer to report user update problems
class EmailStaffUpdateProblem < ApplicationJob
  queue_as :urgent

  def perform(params)
    mailer_method = params.delete('method')
    StaffMailer.send(mailer_method(params)).deliver_now
  end
end
