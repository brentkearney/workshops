class SettingUpdater
  def initialize(setting)
    @setting = setting
  end

  def save
    keep_arrays

    case @setting.var
    when 'Site'
      Setting.Site = @setting.value
    when 'Emails'
      Setting.Emails = @setting.value
    when 'Rooms'
      Setting.Rooms = @setting.value
    when 'Locations'
      Setting.Locations = update_locations
    end
  end

  def keep_arrays
    if @setting.value.is_a?(Hash)
      @setting.value.each do |param_name, param_value|
        if param_value =~ /^\[(.+)\]$/
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
    @setting.value = settings
    unless location_key.blank?
      remove_locations(location_key: location_key.to_sym)
    end
  end

  def remove_locations(location_key:)
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

    add_locations(new_key: new_key.to_sym) unless new_key.blank?
  end

  def add_locations(new_key:)
    (Setting.get_all.keys - ['Site']).each do |section|
      setting = Setting.find_by(var: section)
      section_settings = setting.value

      new_location = {new_key => create_empty_setting(section_settings)}
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
      new_key = values.delete(:new_key) if new_key.blank?
      settings[key] = values
      if !new_key.blank? && new_key != key
        settings[:"#{new_key}"] = settings.delete(:"#{key}")
        rename_location_keys(old_key: key, new_key: new_key)
      end
    end
    @setting.value = settings
  end

  def rename_location_keys(old_key:, new_key:)
    (Setting.get_all.keys - ['Site', 'Locations']).each do |section|
      setting = Setting.find_by(var: section)
      setting_value = setting.value
      setting_value[new_key.to_sym] = setting_value.delete(old_key.to_sym)
      setting.value = setting_value
      setting.save!
    end
  end

  def create_empty_setting(section_settings)
    empty_fields = {}
    unless section_settings.keys.empty?
      section_settings[section_settings.keys.first].each do |key, value|
        empty_fields[key] = ''
      end
    end
    empty_fields
  end
end
