# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class SettingsController < ApplicationController
  before_filter :authenticate_user!
  before_action :get_setting, only: [:edit, :update]
  before_action :get_settings

  def index
    @person = current_user.person
  end

  def edit
    authorize @setting
  end

  def new
    @setting = Setting.new
    authorize @setting
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

  def create
    setting = Setting.new(setting_params)
    authorize setting
    if setting.save
      redirect_to settings_path, notice: %(Added "#{setting.var}" setting!)
    else
      flash[:error] = %(Error saving setting: #{setting.errors})
      render :new
    end
  end

  def get_setting
    @setting = Setting.find_by(var: params[:id]) || Setting.new(var: params[:id])
  end

  def get_settings
    @settings = Setting.get_all
  end

  private

  def setting_params
    params.require(:setting).permit(:var, :value)
  end

end
