# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module ApplicationHelper

  def page_title
    return 'Future Events' if request.path == events_future_path
    return 'Past Events' if request.path == events_past_path
    if request.path =~ /(future|past)\/location\/(\w+)\z/
      return %Q(#{@tense} #{@location} Events)
    end
    return %Q(#{@year} Events) if request.path =~ /events\/year\/(\d{4})/
    if request.path =~ /year\/(\d{4})\/location/
      return %Q(#{@year} #{@location} Events)
    end
    if request.path =~ /events\/(\w+)\/schedule/
      return %Q(#{@event.code} Schedule)
    end
    if request.path =~ /events\/(\w+)\/memberships/
      return %Q(#{@event.code} Members)
    end
    return %Q(#{@event.code}: #{@event.name}) if @event
    Setting.Site[:title]
  end


  def profile_pic(person)
    image_tag "profile.png", alt: "#{person.name}", id: "profile-pic-#{person.id}", class: "img-responsive img-rounded"
  end

  def user_is_staff?
    current_user && current_user.is_staff?
  end

  def user_is_organizer?
    current_user && current_user.is_organizer?(@event)
  end

  def user_is_member?
    current_user && current_user.is_member?(@event)
  end
end
