# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Receives Griddler:Email object, distributes message to confirmed members
class EventMaillist
  def initialize(email)
    @email = email
    @event = Event.find(@email.to[0][:token])
  end

  def send_message
    recipients = []
    @event.confirmed.each do |person|
      to_email = person.email
      if ENV['APPLICATION_HOST'].include?('staging')
        to_email = GetSetting.site_email('webmaster_email')
      end
      recipients << { address: { email: to_email, name: "#{person.name}" } }
    end

    message = {
      from: @email.from[:full],
      subject: @email.subject,
      body: @email.body,
      date: @email.headers['Date']
    }
    MaillistMailer.workshop_maillist(message, recipients)
  end
end
