# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class SettingUpdater
  def initialize(setting)
    @setting = setting
  end

  def save
    keep_arrays
    add_new_field

    case @setting.var
    when 'Site'
      Setting.Site = @setting.value
    when 'Emails'
      Setting.Emails = @setting.value
    when 'Rooms'
      Setting.Rooms = @setting.value
    when 'Locations'
      Setting.Locations = update_locations
    else
      @setting.save
    end
    rewrite_cache
  end

  def rewrite_cache
    Rails.cache.write("settings:#{@setting.var}", @setting.value,
      expires_in: 10.minutes)
  end

  def keep_arrays
    if @setting.value.is_a?(Hash)
      @setting.value.each do |param_name, param_value|
        if param_value.to_s.match?(/^\[(.+)\]$/)
          param_value = param_value.gsub(/^\[|"|'|\]$/, '').
            split(',').map(&:strip)
          @setting.value = @setting.value.merge(param_name => param_value)
        end
      end
    end
  end

  def update_locations
    remove_location
    add_location
    rename_location
    @setting.value
  end

  def remove_location
    settings = @setting.value
    location_key = settings.delete('remove_location')
    @setting.value = settings.except(location_key)
    remove_locations(location_key: location_key) unless location_key.blank?
  end

  def remove_locations(location_key: '')
    (Setting.get_all.keys - ['Site', 'Locations']).each do |section|
      setting = Setting.find_by(var: section)
      new_value = setting.value.except(location_key)
      setting.value = new_value
      setting.save!
    end
  end

  def add_location
    settings = @setting.value
    new_key = settings.delete('new_location')
    @setting.value = settings
    add_locations(new_key: new_key) unless new_key.blank?
  end

  def add_locations(new_key: '')
    (Setting.get_all.keys - ['Site']).each do |section|
      setting = Setting.find_by(var: section)
      section_settings = Setting.send(section)
      new_location = { new_key => create_empty_setting(section_settings) }
      new_value = section_settings.merge(new_location)

      if section == 'Locations'
        @setting.value = new_value
      else
        setting.value = new_value
        setting.save!
      end
    end
  end

  def rename_location
    settings = @setting.value
    @setting.value.each do |key, values|
      new_key = values.delete('new_key')
      settings[key] = values
      if !new_key.blank? && new_key != key
        settings[new_key] = settings.delete(key)
        rename_location_keys(old_key: key, new_key: new_key)
      end
    end
    @setting.value = settings
  end

  def rename_location_keys(old_key: '', new_key: '')
    temp_setting = @setting
    (Setting.get_all.keys - ['Site', 'Locations']).each do |section|
      setting = Setting.find_by(var: section)
      setting_value = setting.value
      setting_value[new_key.to_s] = setting_value.delete(old_key)
      setting.value = setting_value
      @setting = setting
      save
    end
    @setting = temp_setting
  end

  def create_empty_setting(section_settings)
    empty_fields = {}
    unless section_settings.keys.empty?
      section = section_settings[section_settings.keys.first]
      unless section.blank?
        section.each do |key, _value|
          empty_fields[key] = ''
        end
      end
    end
    empty_fields
  end

  def merge_new_field(settings)
    new_field = settings.delete('new_field')
    new_value = settings.delete('new_value')
    settings[new_field] = new_value unless new_field.blank?
    settings
  end

  def add_new_field
    if @setting.var == 'Site'
      @setting.value = merge_new_field(@setting.value)
    else
      settings = @setting.value
      @setting.value.each do |param_key, param_value|
        if param_value.is_a?(Hash)
          settings[param_key.to_s] = merge_new_field(param_value)
        end
      end
      @setting.value = settings
    end
  end
end
