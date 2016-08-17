# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module ScheduleHelper

  def schedule_link item
    link_text = ''
    item.lecture.nil? ? link_class = 'schedule-item' : link_class = 'lecture-item'

    if policy(item).edit?
      link_text = link_to item[:name], event_schedule_edit_path(@event, item), class: link_class
      unless item[:description].blank?
        link_text += link_to " <i class=\"fa fa-toggle-down fa-fw\"></i>".html_safe, '#', html_options = {class: 'item-link', id: "link-#{item[:id]}"}
      end
    else
      if item[:description].blank?
        link_text = "<span class=\"#{link_class}\">#{item[:name]}</span>"
      else
        link_text = link_to "#{item[:name]} <i class=\"fa fa-toggle-down fa-fw\"></i>".html_safe, '#', html_options = {class: "item-link #{link_class}", id: "link-#{item[:id]}"}
      end
    end

    unless item[:description].blank?
      link_text += "\n<div class=\"item-description\" id=\"description-#{item[:id]}\">#{item[:description]}</div>".html_safe
    end

    return link_text.html_safe
  end

  def skip_day?(day)
    day == @event.days.first && @current_user && @current_user.is_staff? && @event.location == 'BIRS'
  end

end