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
    authorize @setting

    @setting.value = update_params
    # redirect_to edit_setting_path(params[:id])
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

  def update_params
    setting_fields = [:new_field, :new_value, :new_location, :remove_location]
    @setting.value.each do |field_name, value|
      if value.is_a?(Hash)
        setting_fields << { "#{field_name}": value.keys <<
          [:new_field, :new_value, :new_key] }
      else
        setting_fields << field_name
      end
    end
    data = params.require(:setting).permit("#{@setting.var}": setting_fields)
    data["#{@setting.var}"]
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
    @setting = Setting.find_by_var(params[:id]) || Setting.new(var: params[:id])
    # rails-settings-cached sometimes adds empty values
    # @setting.value = @setting.value.except!(:"") unless @setting.value.nil?
  end

  def get_settings
    @settings = Setting.get_all
    @tabs = ['Site', 'Emails', 'Locations', 'Rooms']
    @tabs.concat @settings.keys - @tabs
  end
end
