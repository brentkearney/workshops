# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Converts posted parameters into Setting
class SettingParametizer
  attr_reader :setting

  def initialize(params)
    @params = params
    @setting = get_setting
  end

  def get_setting
    @setting = Setting.find_by_var(@params[:id]) ||
               Setting.new(var: @params[:id].to_s.strip, value: {})
  end

  def create_new
    locations = { :new_setting => true }
    Setting.find_by_var('Locations').value.keys.each do |key|
      locations[key.to_s] = {}
    end
    Setting.new(var: @params['setting']['var'].strip, value: locations)
  end

  def organize_params
    @setting.value = update_params
  end

  def update_params
    data = @params.require(:setting).permit(@setting.var => valid_fields)
    data.to_h[@setting.var.to_s]
  end

  def valid_fields
    setting_fields = initial_settings
    @setting.value.each do |field_name, value|
      if value.is_a?(Hash)
        setting_fields << { field_name => field_values(value) }
      else
        setting_fields << field_name
      end
    end
    setting_fields
  end

  def field_values(value)
    permitted_fields = value.keys
    permitted_fields += [:new_field, :new_value]
    permitted_fields << :new_key if @setting.var == 'Locations'
    permitted_fields
  end

  def initial_settings
    if @params['setting']['Locations']
      [:new_location, :remove_location]
    else
      [:new_field, :new_value]
    end
  end
end
