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
      from: email_from,
      recipient: email_recipient,
      subject: message_subject,
      date: message_date,
      attachments: message_attachments,
      status: delivery_status
    }
  end

  def delivery_status
    {
             code: params['event-data']['delivery-status']['code'],
      description: params['event-data']['delivery-status']['description'],
          message: params['event-data']['delivery-status']['message'],
          mxhost: params['event-data']['delivery-status']['mx-host'],
          domain: params['event-data']['recipient-domain']
    }
  end

  def verify_headers
    params['event-data'].key?('message') &&
      params['event-data']['message'].key?('headers')
  end

  def headers
    add_message_param unless verify_headers
    params['event-data']['message']['headers']
  end

  def add_message_param
    params['event-data'].merge!(
      'message' => {
       'headers' => {
          'to' => 'unknown',
          'from' => 'unknown',
          'subject' => 'unknown'
        }
      }
    )
    Rails.logger.debug "\n\nParams is now: #{params.inspect}\n\n"
  end

  def email_from
    headers['from']
  end

  def email_recipient
    params['event-data']['recipient']
  end

  def message_subject
    headers['subject']
  end

  def message_date
    Time.at(params['event-data']['timestamp'].to_i).to_formatted_s(:rfc822)
  end

  def message_attachments
    files = ''
    return files unless params['event-data'].key?('message') &&
      params['event-data']['message'].key?('attachments')

    params['event-data']['message']['attachments'].each do |file|
      files << file['filename'] + ' '
    end
    files
  end
end
