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
  end

  def process
    BounceMailer.bounced_email(normalized_params).deliver_now
  end

  def normalized_params
    {
      original_sender: original_sender,
      from: email_from,
      recipient: original_recipient,
      subject: message_subject,
      status: delivery_status,
      event_code: event_code
    }
  end

  def delivery_status
    {
             code: params['event-data']['delivery-status']['code'],
      description: params['event-data']['delivery-status']['description'],
          message: params['event-data']['delivery-status']['message']
    }

  end

  def original_sender
    return '' unless params['event-data']['message']['headers'].key?('X-WS-Mailer')
    params['event-data']['message']['headers']['X-WS-Mailer']['sender']
  end

  def event_code
    return '' unless params['event-data']['message']['headers'].key?('X-WS-Mailer')
    params['event-data']['message']['headers']['X-WS-Mailer']['event']
  end

  def email_from
    params['event-data']['message']['headers']['from']
  end

  def original_recipient
    params['event-data']['message']['headers']['to']
  end

  def message_subject
    params['event-data']['message']['headers']['subject']
  end
end
