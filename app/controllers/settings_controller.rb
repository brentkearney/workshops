# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class SettingsController < ApplicationController
  before_filter :authenticate_user!
  before_action :get_settings
  before_action :get_setting, only: [:edit, :update]

  # GET /settings
  def index
    redirect_to edit_setting_path('Site')
  end

  # GET /settings/:id/edit
  def edit
    authorize @setting
  end

  # GET /settings/new
  def new
    @setting = Setting.new
    authorize @setting
  end

  # PATCH /settings
  def update
    authorize_and_organize

    if @setting.save
      redirect_to edit_setting_path(params[:id]),
        notice: 'Setting has been updated.'
    else
      redirect_to settings_path,
        error: 'There was a problem saving the setting.'
    end
  end

  # POST /settings
  def create
    @setting = Setting.new(setting_params)
    authorize @setting
    if @setting.save
      redirect_to settings_path, notice: %(Added "#{@setting.var}" setting!)
    else
      flash[:error] = %(Error saving setting: #{@setting.errors})
      render :new
    end
  end

  # POST /settings/delete
  def delete
    setting = Setting.find(delete_params['id'])
    authorize setting
    setting.destroy
    redirect_to settings_path, notice: %(Deleted "#{setting.var_was}" setting!)
  end


  private

  def authorize_and_organize
    authorize @setting
    @setting.value = update_params
  end

  def update_params    
    data = params.require(:setting).permit("#{@setting.var}": valid_fields)
    data["#{@setting.var}"]
  end

  def valid_fields
    setting_fields = initial_settings
    @setting.value.each do |field_name, value|
      if value.is_a?(Hash)
        setting_fields << { "#{field_name}": value.keys << :new_key }
      else
        setting_fields << field_name
      end
    end
    setting_fields
  end

  def initial_settings
    params['setting']['Locations'] ? [:new_location, :remove_location] : Array.new
  end

  def setting_params
    data = params.require(:setting).permit(:var)
    data['var'] = data['var'].to_s.strip
    data['value'] = {}
    data
  end

  def delete_params
    params.require(:setting).permit(:id)
  end

  def get_setting
    @setting = Setting.find_by_var(params[:id]) || Setting.new(var: params[:id], value: {})
  end

  def get_settings
    @settings = Setting.get_all
    @tabs = ['Site', 'Emails', 'Locations', 'Rooms']
    @tabs.concat @settings.keys - @tabs
  end
end
