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
  app_email = Setting.Site['application_email'] unless Setting.Site.blank?
  app_email = ENV['DEVISE_EMAIL'] if app_email.nil?

  default from: app_email

  def missing_email_settings(event)
    Setting.Emails.blank? || Setting.Emails[event.location].blank? ||
      Setting.Emails[event.location]['schedule_staff'].blank?
  end

  def schedule_change(args)
    @event = Event.find_by_code(args[:event_code])
    return if missing_email_settings(@event)
    @change_notice = args[:message]

    mail(to: Setting.Emails[@event.location]['schedule_staff'],
         subject: "[#{@event.code}] Schedule change notice!")
  end

  def event_sync(event, error_messages)
    @event = event
    @error_messages = error_messages
    to_email = Setting.Emails[event.location]['program_coordinator']
    cc_email = Setting.Site['sysadmin_email']
    subject = "!! #{event.code} (#{event.location}) Data errors !!"

    mail(to: to_email, cc: cc_email, subject: subject)
  end

  def notify_sysadmin(event, error)
    to_email = Setting.Site['sysadmin_email']
    subject = if event.nil?
                'Workshops error!'
              else
                "[#{event.code}] (#{event.location}) error"
              end

    @message = error.inspect
    mail(to: to_email, subject: subject, template_name: 'notify_sysadmin')
  end

  def event_update(event, args:)
    @updated_by = args[:updated_by]
    @event_name = "#{event.code}: #{event.name} (#{event.dates})"
    @event_url = event.url
    @workshops_url = event_url(event)

    to_email = Setting.Emails[event.location]['event_updates']
    subject = "[#{event.code}] Event updated!"

    mail(to: to_email, subject: subject)
  end

  def nametag_update(event, args:)
    @short_name = args[:short_name]
    @updated_by = args[:updated_by]
    @event_name = "#{event.code}: #{event.name} (#{event.dates})"
    @workshops_url = event_url(event)

    to_email = Setting.Emails[event.location]['name_tags']
    subject = "[#{event.code}] Name tag change notice!"

    mail(to: to_email, subject: subject)
  end

  def confirmation_notice(membership, msg, to)
    staff_email = Setting.Emails[membership.event.location][to]
    return if staff_email.blank?
    @person = membership.person
    @event = membership.event
    @message = msg
    @membership_url = event_membership_url(@event, membership)
    subject = "[#{@event.code}] membership change!"
    mail(to: staff_email, subject: subject)
  end

  def site_feedback(section:, membership:, message:)
    feedback_email = Setting.Site['webmaster_email']
    return if feedback_email.blank?
    @membership = membership
    @message = message
    @question = 'How was your RSVP experience?'
    subject = "[#{@membership.event.code}] #{section} feedback"
    mail(to: feedback_email, subject: subject)
  end
end
