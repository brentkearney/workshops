# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module ApplicationHelper
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
