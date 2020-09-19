# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Helpers for schedule pages
module ScheduleHelper
  def schedule_link item
    link_text = ''
    item.lecture.nil? ? link_class = 'schedule-item' : link_class = 'lecture-item'

    if policy(item).edit?
      link_text = link_to item[:name], event_schedule_edit_path(@event, item), class: link_class
      unless item[:description].blank?
        link_text += link_to " <i class=\"fa fa-toggle-down fa-fw\" id=\"icon-#{item[:id]}\"></i>".html_safe, '#', { class: 'item-link', id: "link-#{item[:id]}" }
      end
    else
      if item[:description].blank?
        link_text = "<span class=\"#{link_class}\">#{item[:name]}</span>"
      else
        link_text = link_to "#{item[:name]} <i class=\"fa fa-toggle-down fa-fw\"></i>".html_safe, '#', { class: "item-link #{link_class}", id: "link-#{item[:id]}" }
      end
    end

    unless item[:description].blank?
      link_text += "\n<div class=\"item-description\" id=\"description-#{item[:id]}\">#{item[:description]}</div>".html_safe
    end

    link_text.html_safe
  end

  def time_limits(schedule)
    return unless schedule.staff_item
    unless schedule.earliest.nil?
      concat hidden_field_tag 'earliest_hour', schedule.earliest.strftime('%H')
      concat hidden_field_tag 'earliest_minute', schedule.earliest.strftime('%M')
    end
    unless schedule.latest.nil?
      concat hidden_field_tag 'latest_hour', schedule.latest.strftime('%H')
      concat hidden_field_tag 'latest_minute', schedule.latest.strftime('%M')
    end
  end

  def start_or_stop_recording_button(schedule)
    return if schedule.start_time.day != DateTime.now.day
    return if schedule.lecture_id.blank?
    lecture = Lecture.find(schedule.lecture_id)
    return if lecture.blank?
    return unless lecture.filename.blank? && lecture.room == 'Online'
    show_record_button(schedule, lecture)
  end

  def show_record_button(schedule, lecture)
    recording_lecture = Lecture.find_by(event_id: @event.id, is_recording: true)

    if recording_lecture.blank?
      link_to "Start Recording", { controller: "schedule", action: "recording", event_id: @event.code, id: schedule.id, record_action: :start }, method: "post", remote: true, class: 'btn btn-sm btn-success'
    elsif lecture.id == recording_lecture.id
      link_to "Stop Recording", { controller: "schedule", action: "recording", event_id: @event.code, id: schedule.id, record_action: :stop }, method: "post", remote: true, class: "btn btn-sm btn-danger"
    end
  end

  def schedule_form_with_path
    case request.path
    when /new/
      event_schedule_create_path
    when /create/
      new_event_schedule_path
    else
      event_schedule_path
    end
  end
end
