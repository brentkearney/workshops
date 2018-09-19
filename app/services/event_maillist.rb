# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Receives event code & Griddler:Email object, distribute to confirmed members
class EventMaillist
  def initialize(email)
    @email = email
    @event = Event.find(@email.to)
  end

  def send
    recipients = ''
    @event.confirmed.each do |person|
      recipients << %Q("#{person.name}" <#{person.email}>, )
    end
    recipients.chomp!(', ')

    Rails.logger.debug "\n\n" + '*' * 100 + "\n\n"
    Rails.logger.debug "EventMaillist would send message '#{@email.subject}' to these recipients:\n"
    Rails.logger.debug "#{recipents}"
    Rails.logger.debug "\n\n" + '*' * 100 + "\n\n"
  end
end
