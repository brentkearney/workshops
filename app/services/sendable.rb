# app/services/sendable.rb
# Copyright (c) 2020 Banff International Research Station
#
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# methods for maillists to track sending
module Sendable
  attr_writer :email

  def message_id
    msg_id_key = @email.headers.keys.detect { |k| k.downcase == 'message-id' }
    msg_id = @email.headers[msg_id_key]
    if msg_id.blank?
      Rails.logger.debug "\n\nNo Message-ID found in email! Cannot record it.\n\n"
      return
    end
    msg_id.match?('<') ? msg_id.match(/\<(.*)\>/)[1] : msg_id
  end

  def compose_message(subject, destination)
    {
      message_id: message_id,
      sender: @email.from[:full],
      recipient: destination,
      subject: subject,
      date: DateTime.now
    }
  end

  def report_failure(record)
    msg = {
      problem: 'Failed to create Sentmail record for mail list posting.',
      error: record.errors.full_messages,
      data: record,
      email: @email
    }
    StaffMailer.notify_sysadmin(@event.id, msg).deliver_now
  end

  def record_sent_mail(subject, destination)
    message = compose_message(subject, destination)
    record = Sentmail.new(message)
    if record.valid?
      record.save
    else
      report_failure(record)
    end
  end

  def already_sent?(recipient)
    !Sentmail.where(message_id: message_id, recipient: recipient).empty?
  end
end
