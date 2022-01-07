# Copyright (c) 2016 Banff International Research Station
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Notification messages to Staff
class StaffMailer < ApplicationMailer
  app_email = GetSetting.site_email('application_email')
  default from: app_email
  self.delivery_method = :smtp unless Rails.env == 'test'

  def schedule_change(args)
    @event = Event.find_by_id(args[:event_id])
    to_email = GetSetting.email(@event.location, 'schedule_staff')
    @change_notice = args[:message]

    mail(to: to_email, subject: "[#{@event.code}] Schedule change notice!")
  end

  def event_sync(event, error_messages)
    @event = event
    @error_messages = error_messages
    to_email = GetSetting.email(@event.location, 'secretary')
    cc_email = GetSetting.site_email('sysadmin_email')
    subject = "!! #{event.code} (#{event.location}) Data errors !!"

    mail(to: to_email, cc: cc_email, subject: subject)
  end

  def notify_sysadmin(event, error)
    event = Event.find(event) if event.is_a?(Integer)
    to_email = GetSetting.site_email('sysadmin_email')
    subject = if event.nil?
                'Workshops error!'
              else
                "[#{event.code}] (#{event.location}) error"
              end

    @message = error.pretty_inspect
    mail(to: to_email, subject: subject, template_name: 'notify_sysadmin')
  end

  def notify_program_coord(event, subject, error)
    to_email = GetSetting.email(event.location, 'program_coordinator')
    @message = error.pretty_inspect
    mail(to: to_email, subject: subject, template_name: 'notify_sysadmin')
  end

  def event_update(event, args:)
    @updated_by = args[:updated_by]
    @event_name = "#{event.code}: #{event.name} (#{event.dates})"
    @event_url = event.url
    @workshops_url = event_url(event)

    to_email = GetSetting.email(event.location, 'event_updates')
    subject = "[#{event.code}] Event updated!"

    mail(to: to_email, subject: subject)
  end

  def nametag_update(event, args:)
    @short_name = args[:short_name]
    @updated_by = args[:updated_by]
    @event_name = "#{event.code}: #{event.name} (#{event.dates})"
    @workshops_url = event_url(event)

    to_email = GetSetting.email(event.location, 'name_tags')
    subject = "[#{event.code}] Name tag change notice!"

    mail(to: to_email, subject: subject)
  end

  def confirmation_notice(membership, msg, to)
    staff_email = GetSetting.email(membership.event.location, to)
    @membership = membership
    @person = membership.person
    @event = membership.event
    @message = ''
    msg[:message].each do |changed|
      @message << "#{changed}\n\n"
    end
    @updated_by = msg[:updated_by]
    @membership_url = event_membership_url(@event, membership)
    subject = "[#{@event.code}] membership change!"
    mail(to: staff_email, subject: subject)
  end

  def site_feedback(section:, membership:, message:)
    feedback_email = GetSetting.site_email('rsvp_feedback') || ENV['DEVISE_EMAIL']
    return if feedback_email.blank?

    @membership = membership
    @message = message
    @question = 'How was your RSVP experience?'
    subject = "[#{@membership.event.code}] #{section} feedback"
    mail(to: feedback_email, subject: subject)
  end

  def rsvp_failed(membership, args:)
    @membership = membership
    location = membership.event.location
    @error_messages = args['error']
    @failed_save = args['membership']

    to_email = GetSetting.email(location, 'program_coordinator')
    cc_email = GetSetting.site_email('sysadmin_email')
    subject = "[#{@membership.event.code}] Failed RSVP save"
    mail(to: to_email, cc: cc_email, subject: subject)
  end

  def incoming_mail_event(message)
    to_email = GetSetting.site_email('sysadmin_email')
    subject = 'Workshops: incoming message event notice'
    @message = message
    mail(to: to_email, subject: subject, template_name: 'notify_sysadmin')
  end

  def email_conflict(args)
    person_id = args[:person]
    other_person_id = args[:other_person]
    @new_email = args[:new_email]
    @person = Person.find(person_id)
    @other_person = Person.find(other_person_id)

    to_email = GetSetting.site_email('sysadmin_email')
    subject = 'Email conflict'
    @message = %Q("#{@person.name}" <#{@person.email}> (#{@person.id}) tried
      changing their email to #{@new_email}, but it is already taken by
      #{@other_preson.name} (#{@other_person.id}).\n\n
      https://workshops.birs.ca).squish

    mail(to: to_email, subject: subject, template_name: 'notify_sysadmin')
  end
end
