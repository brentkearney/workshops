# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class SettingPolicy
  attr_reader :current_user, :setting

  def initialize(current_user, model)
    @current_user = current_user
    @setting = model.nil? ? Setting.new : model
  end

  def edit?
    current_user.is_admin?
  end

  def method_missing(name, *args)
    current_user.is_admin?
  end

end
