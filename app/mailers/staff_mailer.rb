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

class StaffMailer < ApplicationMailer
  app_email = Setting.Site['application_email'] unless Setting.Site.blank?
  if Setting.Site.blank? || app_email.nil?
    app_email = ENV['DEVISE_EMAIL']
  end

  default from: app_email

  def schedule_change(args)
    type = args[:type] || ''
    user = args[:user] || ''
    original_schedule = args[:original_schedule] || false
    original_lecture = args[:original_lecture] || false
    updated_schedule = args[:updated_schedule] || false
    changed_similar = args[:changed_similar] || false

    @event = Event.find_by_id(original_schedule['event_id'])
    schedule_emails = 'schedule@example.com'
    unless Setting.Emails.blank? ||
           Setting.Emails[@event.location.to_s]['schedule_staff'].nil?
      schedule_emails = Setting.Emails[@event.location.to_s]['schedule_staff']
    end
    to_email = schedule_emails
    subject = "[#{@event.code}] Schedule change notice!"

    publish = 'N/A'
    if original_lecture
      publish = original_lecture.do_not_publish ? 'OFF' : 'ON'
      original_schedule.description = original_lecture.abstract
    end

    @change_notice = %(
    THIS:
      Name: #{original_schedule.name}
      Start time: #{original_schedule.start_time}
      End time: #{original_schedule.end_time}
      Location: #{original_schedule.location}
      Lecture publishing: #{publish}
      Description: #{original_schedule.description}
      Updated by: #{original_schedule.updated_by}
    )

    case type
    when 'create'
      unless original_schedule.lecture_id.blank?
        lecture = Lecture.find_by_id(original_schedule.lecture_id)
        publish = lecture.do_not_publish ? 'OFF' : 'ON'
        @change_notice.sub!('Lecture publishing: N/A',
                           "Lecture publishing: #{publish}")
        @change_notice.sub!('Description: ', "Description: #{lecture.abstract}")
      end

      @change_notice << %(
    WAS ADDED!
      By: #{user} at #{Time.now}
      )

    when 'update'
      unless updated_schedule.lecture_id.blank?
        publish = updated_schedule.lecture.do_not_publish ? 'OFF' : 'ON'
        updated_schedule.description = updated_schedule.lecture.abstract
      end

      @change_notice << %(
    CHANGED TO:
      Name: #{updated_schedule.name}
      Start time: #{updated_schedule.start_time}
      End time: #{updated_schedule.end_time}
      Location: #{updated_schedule.location}
      Lecture publishing: #{publish}
      Description: #{updated_schedule.description}
      Updated by: #{updated_schedule.updated_by}
    )

      if changed_similar
        @change_notice << %(
**** All "#{original_schedule.name}" items at #{original_schedule.start_time.strftime("%H:%M")} were changed to the new time. ****
      )
      end

    when 'destroy'
      unless original_schedule.lecture_id.blank?
        lecture = Lecture.find_by_id(original_schedule.lecture_id)
        publish = lecture.do_not_publish ? 'OFF' : 'ON'
        @change_notice.sub!('Lecture publishing: N/A',
                           "Lecture publishing: #{publish}")
        @change_notice.sub!('Description: ', "Description: #{lecture.abstract}")
      end

      @change_notice << %(
    WAS DELETED!
      By: #{user} at #{Time.now}
      )
    end

    mail(to: to_email, subject: subject)
  end

  def event_sync(event, error_messages)
    @event = event
    @error_messages = error_messages
    to_email = Setting.Emails[event.location.to_s]['program_coordinator']
    cc_email = Setting.Site['sysadmin_email']
    subject = "!! #{event.code} (#{event.location}) Data errors !!"

    mail(to: to_email, cc: cc_email, subject: subject)
  end

  def notify_sysadmin(event, error)
    to_email = Setting.Site['sysadmin_email']

    if event.nil?
      subject = "Workshops error!"
    else
      subject = "[#{event.code}] (#{event.location}) error"
    end

    @message = error.inspect
    mail(to: to_email, subject: subject, template_name: 'notify_sysadmin')
  end

  def event_update(original_event: event, args: params)
    event = original_event
    @updated_by = args[:updated_by]
    @event_name = "#{event.code}: #{event.name} (#{event.dates})"
    @event_url = event.url
    @workshops_url = event_url(event)

    to_email = Setting.Emails[event.location.to_s]['event_updates']
    subject = "[#{event.code}] Event updated!"

    mail(to: to_email, subject: subject)
  end

  def nametag_update(original_event: event, args: params)
    event = original_event
    @short_name = args[:short_name]
    @updated_by = args[:updated_by]
    @event_name = "#{event.code}: #{event.name} (#{event.dates})"
    @workshops_url = event_url(event)

    to_email = Setting.Emails[event.location.to_s]['name_tags']
    subject = "[#{event.code}] Name tag change notice!"

    mail(to: to_email, subject: subject)
  end

  def confirmation_notice(membership, msg)
    staff_email = Setting.Emails["#{membership.event.location}"]['confirmation_notices']
    unless staff_email.blank?
      @person = membership.person
      @event = membership.event
      @message = msg
      subject = "[#{@event.code}] membership change!"
      mail(to: staff_email, subject: subject)
    end
  end

  def site_feedback(section:, membership:, message:)
    feedback_email = Setting.Site['webmaster_email']
    unless feedback_email.blank?
      @membership = membership
      person = membership.person
      @message = message
      @question = 'How was your RSVP experience?'
      subject = "[#{@membership.event.code}] #{section} feedback"
      mail(to: feedback_email, subject: subject)
    end
  end
end
