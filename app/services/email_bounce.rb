# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Class for processing bounced email from Mailgun
class EmailBounce
  attr_reader :params

  def initialize(params)
    @params = params
    Rails.logger.debug "\n\nEmailBounce recieved:\n#{params.pretty_inspect}\n\n"
  end

  def process
    BounceMailer.bounced_email(normalized_params).deliver_now
  end

  def normalized_params
    {
      original_sender: original_sender,
      from: email_from,
      recipient: original_recipient,
      subject: subject,
      reason: params['delivery-status'],
      event_code: event_code
    }
  end

  def original_sender
    params['message']['headers']['X-WS-Mailer']['sender']
  end

  def event_code
    params['message']['headers']['X-WS-Mailer']['event']
  end

  def email_from
    params['message']['headers']['from']
  end

  def original_recipient
    params['message']['headers']['to']
  end

  def subject
    params['message']['headers']['subject']
  end
end
