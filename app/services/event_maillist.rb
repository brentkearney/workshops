# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Receives Griddler:Email object, distributes message to confirmed members
class EventMaillist
  def initialize(email, event)
    @email = email
    @event = event
  end

  def send_message
    subject = @email.subject
    subject = "[#{@event.code}] #{subject}" unless subject.include?(@event.code)

    body = @email.body
    prelude = '-' * 75 + "\n"
    prelude << "Message from #{@email.from[:full]} to the #{@event.code} workshop on #{@email.headers['Date']}:"
    prelude << "\n" + '-' * 75 + "\n\n"
    body = prelude + body

    message = {
      from: @email.to[0][:email],
      subject: @email.subject,
      body: body
    }

    @event.confirmed.each do |person|
      recipient = %Q("#{person.name}" <#{person.email}>)
      if ENV['APPLICATION_HOST'].include?('staging') && @event.code !~ /666/
        recipient = GetSetting.site_email('webmaster_email')
      end
      resp = MaillistMailer.workshop_maillist(message, recipient).deliver_now!
      if !resp.nil? && resp['total_rejected_recipients'] != 0
        StaffMailer.notify_sysadmin(@event.id, resp).deliver_now
      end
    end
  end
end
