# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Griddler class for processing incoming email
class EmailProcessor
  attr_accessor :valid_email

  def initialize(email)
    @email = email
  end

  def process
    extract_recipients.each do |list_params|
      EventMaillist.new(@email, list_params).send_message
    end
  end

  private

  def extract_recipients
    maillists = []
    invalid_sender = false
    recipients = @email.to + @email.cc

    recipients.each do |recipient|
      to_email = recipient[:email]
      code = recipient[:token]
      group = 'Confirmed'
      code, group = code.split('-') if code =~ /-/

      if code =~ /#{GetSetting.code_pattern}/
        event = Event.find(code)
        unless event.blank?
          if valid_sender?(event, to_email)
            maillists << {
              event: event,
              group: member_group(group),
              destination: to_email
            }
          else
            invalid_sender = true
          end
        end
      end
    end
    if maillists.empty? && !invalid_sender
      EmailInvalidCodeBounceJob.perform_later(email_params)
    end
    maillists
  end

  def member_group(group)
    return 'orgs' if group == 'orgs' || group == 'organizers'
    return 'all' if group == 'all'
    Membership::ATTENDANCE.each do |status|
      return status if group.titleize == status
    end
  end

  def valid_sender?(event, to_email)
    from_email = @email.from[:email]
    send_report and return false unless EmailValidator.valid?(from_email)
    person = Person.find_by_email(from_email)
    return true if person && allowed_people(event).include?(person)
    params = email_params.merge(event_code: event.code, to: to_email)
    EmailFromNonmemberBounceJob.perform_later(params)
    return false
  end

  def allowed_people(event)
    event.confirmed + event.organizers + event.staff
  end

  def send_report
    msg = {
            problem: 'Mail list submission with invalid sender address',
            email_params: email_params,
            email_object: @email.inspect
          }
    StaffMailer.notify_sysadmin(@event, msg).deliver_now
  end

  def email_recipients
    @email.to.map {|e| e[:email] } + @email.cc.map {|e| e[:email] }
  end

  def email_params
    {
      to: email_recipients,
      from: @email.from[:full],
      subject: @email.subject,
      body: @email.body,
      date: @email.headers['Date']
    }
  end
end
