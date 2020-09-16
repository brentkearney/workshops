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
    return if @email.nil? || skip_vacation_notices

    extract_recipients.each do |list_params|
      next if already_delivered?(list_params[:destination])
      EventMaillist.new(@email, list_params).send_message
    end
  end

  private

  def skip_vacation_notices
    subject = @email.subject.downcase
    subject.include?("bounce notice") || subject.include?("out of office") ||
      subject.include?("vacation notice") || subject.include?("away notice")
  end

  def already_delivered?(recipient)
    msg_id_key = @email.headers.keys.detect { |k| k.downcase == 'message-id' }
    msg_id = @email.headers[msg_id_key]
    return if msg_id.blank?
    message_id = msg_id.match?('<') ? msg_id.match(/\<(.*)\>/)[1] : msg_id
    !Sentmail.where(message_id: message_id, recipient: recipient).empty?
  end

  # assembles valid maillists from To:, Cc:, Bcc: fields
  def extract_recipients
    recipients = @email.to + @email.cc + @email.bcc

    unless @email.recipient.blank? || recipients.include?(@email.recipient)
      rcpt = @email.recipient
      email = rcpt.match?('<') ? rcpt.match(/\<(.*)\>/)[1] : rcpt
      email_name = rcpt.match?('<') ? rcpt.match(/^(.*)\</)[1] : ''
      recipient = {
        token: rcpt.match(/^(.*)@/)[1],
        host:  rcpt.match(/@(.*)$/)[1],
        email: email,
        full: rcpt,
        name: email_name
      }
      recipients << recipient
    end

    compose_maillists(recipients)
  end

  def validate_parameters(to_email, code, group)
    code_pattern = GetSetting.code_pattern
    unless code.match?(/#{code_pattern}/)
      return 'Event code does not match valid code pattern.'
    end

    event = Event.find(code)
    if event.blank?
      return "No event found with code: #{code}."
    end

    unless valid_sender?(event, to_email, group)
      from_email = @email.from[:email].downcase.strip
      return "#{from_email} is not authorized to send to #{code}-#{group}."
    end

    return ''
  end

  def compose_maillists(recipients)
    maillist_domain = GetSetting.site_setting('maillist_domain')
    valid_destinations = []
    problems = []
    recipients.uniq.each do |recipient|
      # Skip Outlook webmaster=webmaster@ auto-reply messages
      next if recipient[:full].match?(/(.+)=(.+)@/)

      # messages from maillist_domain include a list of Workshops mailists
      next if recipient[:email].include?("#{maillist_domain}")

      to_email, code, group = extract_recipient(recipient)

      problem = validate_parameters(to_email, code, group)
      if problem.empty?
        valid_destinations << {
          event: Event.find(code),
          group: member_group(group),
          destination: to_email
        }
      else
        problems << problem
      end
    end

    if valid_destinations.empty?
      message = problems.join(", ")
      send_report({ problem: message })
      if message.include?("code")
        EmailInvalidCodeBounceJob.perform_later(email_params)
      end
      return []
    end

    valid_destinations
  end

  def extract_recipient(recipient)
    to_email = recipient[:email]
    code = recipient[:token] # part before the @
    group = 'Confirmed'
    code, group = code.split('-') if code.match?(/-/)
    return [to_email, code, group]
  end

  def member_group(group)
    group.downcase!
    return 'orgs' if group == 'orgs' || group == 'organizers'
    return 'all' if group == 'all'
    return 'speakers' if group == 'speakers'

    Membership::ATTENDANCE.each do |status|
      return status if group.titleize == status
    end
  end

  def valid_sender?(event, to_email, group)
    from_email = @email.from[:email].downcase.strip
    unless EmailValidator.valid?(from_email)
      send_report({ problem: "From: email is invalid: #{from_email}." })
      return false
    end

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
    %w(confirmed orgs organizers).include?(group.downcase)
  end

  def organizers_and_staff(event)
    event.organizers + event.staff
  end

  def send_report(problem = nil)
    msg = {
            problem: 'Unknown',
            email_params: email_params,
            email_object: @email.inspect
          }
    msg.merge!(problem) unless problem.nil?
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
