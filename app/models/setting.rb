# RailsSettings Model
class Setting < RailsSettings::Base
  TTL = 1.minute
  attr_accessor :new_field, :new_value
  before_save :merge_fields, :convert_type
  after_update :rewrite_cache
  after_create :rewrite_cache
  namespace Rails.env

  def name(key)
    location = Setting.find_by(var: 'Locations').value
    if location.key? key
      location["#{key}"]['Name']
    else
      key
    end
  end

  def rewrite_cache
    Rails.cache.write("settings:#{self.var}", self.value, expires_in: TTL)
  end


  def merge_fields
    add_new_location

    if self.value.first.second.is_a?(Hash)
      settings = self.value.except(:'')
      self.value.except(:'').each do |param_key, param_value|
        new_field = param_value.delete(:new_field)
        new_value = param_value.delete(:new_value)
        param_value.merge!("#{new_field}": new_value) unless new_field.blank?

        new_key = param_value.delete(:new_key)
        settings["#{param_key}"] = param_value
        if !new_key.blank? && new_key != param_key
          settings["#{new_key}"] = settings.delete("#{param_key}")
        end
      end
      self.value = settings
    else
      settings = self.value
      new_string_field = settings.delete(:new_field)
      new_string_value = settings.delete(:new_value)
      self.value = settings.merge("#{new_string_field}": new_string_value)
    end
  end

  def add_new_location
    if self.value.keys.include? 'new_location'
      settings = self.value
      new_location_key = settings.delete(:new_location)

      skeleton = {}
      settings["#{settings.keys.first}"].each do |key, value|
        skeleton[:"#{key}"] = ''
      end

      new_location = {"#{new_location_key}":
                      skeleton.except(:new_field, :new_value, :new_key)}
      self.value = settings.merge(new_location)
    end
  end

  # Save arrays as arrays (not strings)
  def convert_type
    self.value.each do |param_name, param_value|
      if param_value =~ /^\[(.+)\]$/
        param_value = param_value.gsub(/^\[|"|'|\]$/, '').split(',').map(&:strip)
        self.value = self.value.merge("#{param_name}": param_value)
      end
    end
  end
end
