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
      location[:"#{key}"][:Name]
    else
      key
    end
  end

  def rewrite_cache
    Rails.cache.write("settings:#{self.var}", self.value, expires_in: TTL)
  end

  def merge_fields
    unless Setting.Locations.nil?
      # Are these {:location => {key, val},...}, or just {key, value} settings?
      if (Setting.Locations.keys.map(&:to_s) & self.value.keys).empty?
        settings = self.value
        new_string_field = settings.delete(:new_field)
        new_string_value = settings.delete(:new_value)
        self.value = settings.merge("#{new_string_field}": new_string_value)
      else
        # :EO => {:name=> 'Example Org', ... }
        self.value.each do |param_key, param_value|
          new_field = param_value.delete(:new_field)
          new_value = param_value.delete(:new_value)
          param_value.merge!("#{new_field}": new_value) unless new_field.blank?

          new_key = param_value.delete(:new_key)
          self.value = {"#{new_key}": param_value} unless new_key.blank?
        end
      end
    end
  end

  # Don't save arrays as strings
  def convert_type
    self.value.each do |param_name, param_value|
      if param_value =~ /^\[(.+)\]$/
        param_value = param_value.gsub(/^\[|"|'|\]$/, '').split(',').map(&:strip)
        self.value = self.value.merge("#{param_name}": param_value)
      end
    end
  end
end
