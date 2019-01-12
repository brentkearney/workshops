# app/jobs/email_confirmation_job.rb
#
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Connects to legacy database to replace a person record with another one
class EmailConfirmationJob < ApplicationJob
  queue_as :urgent

  rescue_from(RuntimeError) do |error|
    if error.message == 'JSON::ParserError'
      StaffMailer.notify_sysadmin(nil, error).deliver_now
    else
      retry_job wait: 1.minutes, queue: :default
    end
  end

  def perform(replace_id, replace_with_id)
    # send email to confirm they own replace_with's email account

  end
end
