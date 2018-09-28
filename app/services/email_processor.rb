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
    @valid_email = false
    @event = nil
  end

  def process
    validate_recipient
    validate_sender
    EventMaillist.new(@email).send_message if valid_email
  end

  private

  def validate_recipient
    to = @email.to[0][:token]

    if to =~ /#{GetSetting.code_pattern}/
      @event = Event.find_by_code(to)
      @valid_email = true unless @event.blank?
    end

    EmailInvalidCodeBounceJob.perform_later(email_params) unless @valid_email
  end

  def validate_sender
    return if @event.blank?
    from_email = @email.from[:email]
    send_report and return unless EmailValidator.valid?(from_email)
    person = Person.find_by_email(from_email)

    if person.blank? || @event.confirmed.include?(person).blank?
      @valid_email = false
      EmailFromNonmemberBounceJob.perform_later(email_params)
    else
      @valid_email = true
    end
  end

  def send_report
    msg = {
            problem: 'Mail list submission with invalid sender address',
            email_params: email_params,
            email_object: @email.inspect
          }
    StaffMailer.notify_sysadmin(@event, msg).deliver_now
  end

  def email_params
    {
      to: @email.to[0][:email],
      from: @email.from[:full],
      subject: @email.subject,
      body: @email.body,
      date: @email.headers['Date']
    }
  end
end
