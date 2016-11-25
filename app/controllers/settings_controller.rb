# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class SettingsController < ApplicationController
  before_filter :authenticate_user!
  before_action :get_setting, only: [:edit, :update]
  before_action :get_settings

  # GET /settings
  def index
    @person = current_user.person
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

    @setting.value = update_values
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

  def get_setting
    @setting = Setting.find_by(var: params[:id]) ||
      Setting.new(var: params[:id])
  end

  def get_settings
    @settings = Setting.get_all
  end


  def update_values
    updated_setting = update_params
    new_field = updated_setting.delete('new_field')
    new_value = updated_setting.delete('new_value')
    unless new_field.empty?
      updated_setting.merge!("#{new_field}": "#{new_value}")
    end
    updated_setting
  end

  def update_params
    setting_fields = ['new_field', 'new_value']
    @setting.value.each do |field_name, value|
      setting_fields << field_name
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
end
