# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class SettingsController < ApplicationController
  before_filter :authenticate_user!
  before_action :get_settings
  before_action :get_parametizer, except: [:index, :new]

  # GET /settings
  def index
    redirect_to edit_setting_path('Site')
  end

  # GET /settings/:id/edit
  def edit
    @setting = @setting_params.setting
    authorize @setting
  end

  # GET /settings/new
  def new
    @setting = Setting.new
    authorize @setting
  end

  # PATCH /settings
  def update
    authorize Setting
    @setting_params.organize_params

    SettingUpdater.new(@setting_params.setting).save
    redirect_to edit_setting_path(params[:id]),
      notice: 'Setting has been updated.'
  end

  # POST /settings
  def create
    @setting = @setting_params.create_new
    authorize @setting

    if @setting.save
      redirect_to edit_setting_path(@setting.var),
        notice: %(Added "#{@setting.var}" setting!)
    else
      flash[:error] = %(Error saving setting: #{@setting.flash_error})
      render :new
    end
  end

  # POST /settings/delete
  def delete
    setting = Setting.find(delete_params['id'])
    authorize setting
    if setting.destroy
      redirect_to settings_path, notice: %(Deleted "#{setting.var_was}" setting!)
    else
      flash[:error] = %(Error deleting setting: #{setting.errors.full_messages})
    end
  end


  private

  def delete_params
    params.require(:setting).permit(:id)
  end

  def get_settings
    @settings = Setting.get_all
    @tabs = ['Site', 'Emails', 'Locations', 'Rooms']
    @tabs.concat @settings.keys - @tabs
  end

  def get_parametizer
    @setting_params = SettingParametizer.new(params)
  end
end
