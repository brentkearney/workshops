# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class SettingsController < ApplicationController
  before_filter :authenticate_user!
  before_action :get_setting, only: [:edit, :update]

  def index
    @settings = Setting.get_all
    @person = current_user.person
  end

  def edit
    authorize @setting
    @settings = Setting.get_all
  end

  def update
    if @setting.value != params[:setting][:value]
        @setting.value = params[:setting][:value]
        @setting.save
        redirect_to settings_path, notice: 'Setting has been updated.'
      else
        redirect_to settings_path
      end
  end

  def get_setting
    @setting = Setting.find_by(var: params[:id]) || Setting.new(var: params[:id])
  end

  def setting_params
    params.require(:settings)
  end
end
