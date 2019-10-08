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

  # assembles valid maillists from To: and Cc: fields
  def extract_recipients
    maillists = []
    invalid_sender = false
    recipients = @email.to + @email.cc + @email.bcc

    recipients.each do |recipient|
      to_email = recipient[:email]
      code = recipient[:token] # part before the @
      group = 'Confirmed'
      code, group = code.split('-') if code =~ /-/

      if code =~ /#{GetSetting.code_pattern}/
        event = Event.find(code)
        unless event.blank?
          if valid_sender?(event, to_email, group)
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
      send_report({ recipients: recipients })
    end

    maillists
  end

  def member_group(group)
    return 'orgs' if group.downcase == 'orgs' || group.downcase == 'organizers'
    return 'all' if group.downcase == 'all'
    Membership::ATTENDANCE.each do |status|
      return status if group.titleize == status
    end
  end

  def valid_sender?(event, to_email, group)
    from_email = @email.from[:email].downcase.strip
    send_report and return false unless EmailValidator.valid?(from_email)
    person = Person.find_by_email(from_email)

    return true if organizers_and_staff(event).include?(person)

    params = email_params.merge(event_code: event.code, to: to_email)
    unless event.confirmed.include?(person)
      EmailFromNonmemberBounceJob.perform_later(params)
      return false
    end

    return true if allowed_group?(group)
    UnauthorizedSubgroupBounceJob.perform_later(params)
    return false
  end

  # groups that Confirmed participants (non-organizers) may send to
  def allowed_group?(group)
    %w(confirmed all orgs organizers).include?(group.downcase)
  end

  def organizers_and_staff(event)
    event.organizers + event.staff
  end

  def send_report(other_info = nil)
    msg = {
            problem: 'Mail list submission with invalid sender address',
            email_params: email_params,
            email_object: @email.inspect
          }
    msg.merge(other_info) unless other_info.nil?
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
