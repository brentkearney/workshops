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
    Rails.logger.debug "\n\n" + '*' * 100 + "\n\n"
    Rails.logger.debug "EmailProcessor received email: '#{@email.subject}'.\n"

    EventMaillist.new(@email).send_message if valid_email?
    Rails.logger.debug "\n\n" + '*' * 100 + "\n\n"
  end


  private

  def valid_email?
    Rails.logger.debug "... testing validity of #{@email.to}..."
    recipient = @email.to[0][:token]
    Rails.logger.debug "Recipient is: #{recipient}"
    return true if recipient =~ /#{GetSetting.code_pattern}/ &&
      Event.find_by_code(recipient) != nil

    Rails.logger.debug "NOT VALID! Sending bounce..."
    send_bounce
    return false
  end

  def send_bounce
    EmailInvalidCodeBounceJob.perform_later(bad_email_params)
  end

  def bad_email_params
    Rails.logger.debug "bad_email_params():"
    Rails.logger.debug "to: #{@email.to[0][:token]}"
    Rails.logger.debug "from: #{@email.from[:full]}"
    {
      to: @email.to[0][:email],
      from: @email.from[:full],
      subject: @email.subject,
      body: @email.body,
      date: @email.headers['Date']
    }
  end
end
