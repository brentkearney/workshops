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

  def skip_day?(day)
    day == @event.days.first && @current_user && @current_user.is_staff? &&
      @event.location == 'BIRS'
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
end
