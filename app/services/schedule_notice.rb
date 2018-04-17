# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# ScheduleNotice prepares schedule change notices, sends to StaffMailer
class ScheduleNotice
  attr_reader :event, :args

  def initialize(args)
    @args = args
    @event = find_event
  end

  def update
    original_schedule = args[:original_schedule]
    updated_schedule = args[:updated_schedule]
    original_lecture = args[:original_lecture] || false
    changed_similar = args[:changed_similar] || false

    publish = 'N/A'
    if original_lecture
      publish = original_lecture.do_not_publish ? 'OFF' : 'ON'
      original_schedule.description = original_lecture.abstract
    end

    change_notice = %(
    THIS:
      Name: #{original_schedule.name}
      Start time: #{original_schedule.start_time}
      End time: #{original_schedule.end_time}
      Location: #{original_schedule.location}
      Lecture publishing: #{publish}
      Description: #{original_schedule.description}
      Updated by: #{original_schedule.updated_by}
    )

    unless updated_schedule.lecture_id.blank?
      publish = updated_schedule.lecture.do_not_publish ? 'OFF' : 'ON'
      updated_schedule.description = updated_schedule.lecture.abstract
    end

    change_notice << %(
    CHANGED TO:
      Name: #{updated_schedule.name}
      Start time: #{updated_schedule.start_time}
      End time: #{updated_schedule.end_time}
      Location: #{updated_schedule.location}
      Lecture publishing: #{publish}
      Description: #{updated_schedule.description}
      Updated by: #{updated_schedule.updated_by}
      Updated at: #{updated_schedule.updated_at}
    )

    if changed_similar
      time = original_schedule.start_time.strftime("%H:%M")
      change_notice << %(
**** All "#{original_schedule.name}" items at #{time} were changed to the new time. ****
    )
    end

    invoke_mailer(message: change_notice)
  end

  def create
    schedule = args[:schedule]

    publish = 'N/A'
    unless schedule.lecture_id.blank?
      lecture = Lecture.find_by_id(schedule.lecture_id)
      publish = lecture.do_not_publish ? 'OFF' : 'ON'
      schedule.description = schedule.lecture.abstract
    end

    change_notice = %(
    THIS:
      Name: #{schedule.name}
      Start time: #{schedule.start_time}
      End time: #{schedule.end_time}
      Location: #{schedule.location}
      Lecture publishing: #{publish}
      Description: #{schedule.description}

    WAS ADDED by: #{schedule.updated_by} at #{schedule.updated_at}
    )

    invoke_mailer(message: change_notice)
  end

  def destroy
    schedule = args[:schedule]
    changed_similar = args[:changed_similar] || false

    publish = 'N/A'
    unless schedule.lecture_id.blank?
      lecture = Lecture.find_by_id(schedule.lecture_id)
      publish = lecture.do_not_publish ? 'OFF' : 'ON'
      schedule.description = schedule.lecture.abstract
    end

    change_notice = %(
    THIS:
      Name: #{schedule.name}
      Start time: #{schedule.start_time}
      End time: #{schedule.end_time}
      Location: #{schedule.location}
      Lecture publishing: #{publish}
      Description: #{schedule.description}

    WAS DELETED by: #{schedule.updated_by} at #{schedule.updated_at}
    )

    if changed_similar
      time = schedule.start_time.strftime("%H:%M")
      change_notice << %(
**** All "#{schedule.name}" items at #{time} were deleted. ****
    )
    end

    invoke_mailer(message: change_notice)
  end


  private

  def find_event
    schedule = @args[:original_schedule] || @args[:schedule]
    Event.find_by_id(schedule['event_id'])
  end

  def invoke_mailer(message: '')
    EmailStaffScheduleNoticeJob.perform_later(event.id, message)
  end
end
