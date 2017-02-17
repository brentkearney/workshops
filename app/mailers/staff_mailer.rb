# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class StaffMailer < ApplicationMailer
  default from: Setting.Site['application_email']

  def schedule_change(schedule, type:, user:, updated_schedule: false, changed_similar: false)
    @event = schedule.event
    to_email = Setting.Emails[@event.location.to_sym]['schedule_staff']
    subject = "[#{@event.code}] Schedule change notice!"
    if schedule.lecture.nil?
      publish = 'N/A'
    else
      publish = schedule.lecture.do_not_publish ? 'OFF' : 'ON'
    end


    @change_notice = %Q(
    THIS:
      Name: #{schedule.name}
      Start time: #{schedule.start_time}
      End time: #{schedule.end_time}
      Location: #{schedule.location}
      Lecture publishing: #{publish}
      Description: #{schedule.description}
    )

    case type
      when :create
        @change_notice << %Q(
    WAS ADDED!
      By: #{user} at #{Time.now}
        )

      when :update
        @change_notice << %Q(
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
          @change_notice << %Q(
**** All "#{schedule.name}" items at #{schedule.start_time.strftime("%H:%M")} were changed to the new time. ****
      )
        end

      when :destroy
        @change_notice << %Q(
    WAS DELETED!
      By: #{user} at #{Time.now}
        )
    end

    mail(to: to_email, subject: subject, Importance: 'High', 'X-Priority': 1)
  end

  def event_sync(event, error_messages)
    @event = event
    @error_messages = error_messages
    to_email = Setting.Emails[event.location.to_sym]['program_coordinator']
    cc_email = Setting.Site['sysadmin_email']
    subject = "!! #{event.code} (#{event.location}) Data errors !!"

    mail(to: to_email, cc: cc_email, subject: subject)
  end

  def notify_sysadmin(event, error)
    to_email = Setting.Site['sysadmin_email']

    if event.nil?
      subject = "Workshops error!"
    else
      subject = "[#{event.code}] (#{event.location}) error from #{error.object.class}"
    end

    @message = error.object.inspect.to_s + "\n\n" + error.message.to_s
    mail(to: to_email, subject: subject, Importance: 'High', 'X-Priority': 1, template_name: 'notify_sysadmin')
  end

  def event_update(original_event: event, args: params)
    event = original_event
    @updated_by = args[:updated_by]
    @event_name = "#{event.code}: #{event.name} (#{event.dates})"
    @event_url = Setting.Site[:event_url]
    @workshops_url = event_url(event)

    to_email = Setting.Emails[event.location.to_sym]['event_updates']
    subject = "[#{event.code}] Event updated!"

    mail(to: to_email, subject: subject, Importance: 'High', 'X-Priority': 1)
  end

  def nametag_update(original_event: event, args: params)
    event = original_event
    @short_name = args[:short_name]
    @updated_by = args[:updated_by]
    @event_name = "#{event.code}: #{event.name} (#{event.dates})"
    @workshops_url = event_url(event)

    to_email = Setting.Emails[event.location.to_sym]['name_tags']
    subject = "[#{event.code}] Name tag change notice!"

    mail(to: to_email, subject: subject, Importance: 'High', 'X-Priority': 1)
  end
end
