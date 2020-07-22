# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class LecturePolicy
  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @lecture = model.nil? ? Lecture.new : model
  end

  # Only organizers and admins can change lectures
  def method_missing(*)
    if @current_user
      @current_user.is_organizer?(@lecture.event) || @current_user.is_admin?
    end
  end

end
