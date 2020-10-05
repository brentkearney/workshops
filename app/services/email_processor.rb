# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Griddler class for processing incoming email
class EmailProcessor
  attr_accessor :valid_email
  include Sendable

  def initialize(email)
    @email = email
  end

  def process
    return if @email.nil? || skip_vacation_notices

    extract_recipients.each do |list_params|
      next if already_sent?(list_params[:destination])
      EventMaillist.new(@email, list_params).send_message
    end
  end

  private

  def skip_vacation_notices
    subject = @email.subject.downcase
    subject.include?("bounce notice") || subject.include?("out of office") ||
      subject.include?("vacation notice") || subject.include?("away notice") ||
      subject.include?("automatic reply")
  end

  def parse_angle_brackets(rcpt)
    email_address = rcpt.match?('<') ? rcpt.match(/\<(.*)\>/)[1] : rcpt
    email_name = rcpt.match?('<') ? rcpt.match(/^(.*)\</)[1] : ''
    [email_address.strip, email_name.strip]
  end

  def recipient_hash(recipient_email)
    email_address, email_name = parse_angle_brackets(recipient_email)
    {
      token: email_address.match(/^(.*)@/)[1].strip,
      host:  email_address.match(/@(.*)$/)[1].strip,
      email: email_address.strip,
      full: recipient_email.strip,
      name: email_name.strip
    }
  end

  def already_added?(recipients, email_address)
    !recipients.detect { |r| r[:email] == email_address }.blank?
  end

  # @email.recipient was added at config/initializers/griddler.rb
  def recipient_field(recipients)
    return if @email.recipient.blank?
    new_recipients = []
    @email.recipient.split(',').each do |recipient_email|
      email_address, _email_name = parse_angle_brackets(recipient_email)
      unless already_added?(recipients, email_address)
        new_recipients << recipient_hash(recipient_email)
      end
    end
    new_recipients
  end

  # assembles valid maillists from To:, Cc:, Bcc:, and :recipient fields
  def extract_recipients
    recipients = @email.to + @email.cc + @email.bcc
    recipients = recipients + recipient_field(recipients)
    compose_maillists(recipients.reject(&:blank?))
  end

  def validate_parameters(to_email, code, group)
    code_pattern = GetSetting.code_pattern
    unless code.match?(/#{code_pattern}/)
      return "Event code \"#{code}\" does not match pattern \"#{code_pattern}\"."
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
    code = recipient[:token].strip # part before the @
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
    # non_member_bounce(event, to_email) and return false if person.blank?

    return true if organizers_and_staff(event).include?(person)

    unless event.confirmed.include?(person)
      non_member_bounce(event, to_email)
      return false
    end

    return true if allowed_group?(group)
    UnauthorizedSubgroupBounceJob.perform_later(email_params)
    return false
  end

  def non_member_bounce(event, to_email)
    params = email_params.merge(event_code: event.code, to: to_email)
    EmailFromNonmemberBounceJob.perform_later(params)
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
