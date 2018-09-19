# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Griddler class for processing incoming email
class EmailProcessor
  def initialize(email)
    @email = email
  end

  def process
    EventMaillist.send(@email) if valid_email?
  end


  private

  def valid_email?
    return true if @email.to =~ /#{GetSetting.code_pattern}/ &&
      Event.find_by_code(@email.to) != nil

    send_bounce
    return false
  end

  def send_bounce
    EmailInvalidCodeBounceJob.perform_later(bad_email_params)
  end

  def bad_email_params
    {
      to: @email.headers['To'],
      from: @email.from,
      subject: @email.subject,
      body: @email.body
    }
  end
end
