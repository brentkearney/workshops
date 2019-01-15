# app/jobs/confirm_email_replacement_job.rb
#
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Initiates ConfirmEmailChange job to confirm replacing person records
class ConfirmEmailReplacementJob < ApplicationJob
  queue_as :urgent

  def perform(confirm_id)
    ConfirmEmailMailer.send_msg(confirm_id, mode: 'replace').deliver_now
    ConfirmEmailMailer.send_msg(confirm_id, mode: 'replace_with').deliver_now
  end
end
