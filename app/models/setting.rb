# RailsSettings Model
class Setting < RailsSettings::Base
  attr_accessor :new_key, :new_value
  before_save :merge_fields, :convert_type
  after_update :clear_cache
  namespace Rails.env

  def clear_cache
    Rails.cache.delete("settings:#{self.var}")
  end

  def merge_fields
    self.value.each do |param_key, param_value|
      if param_value.is_a?(Hash)
        new_field = param_value.delete(:new_field)
        new_value = param_value.delete(:new_value)
        param_value.merge!("#{new_field}": new_value) unless new_field.blank?

        new_key = param_value.delete(:new_key)
        self.value = {"#{new_key}": param_value} unless new_key.blank?
      end
    end
  end

  # Don't save arrays as strings
  def convert_type
    self.value.each do |param_name, param_value|
      if param_value =~ /^\[(.+)\]$/
        param_value = param_value.gsub(/^\[|"|\]$/, '').split(',').map(&:strip)
        self.value = self.value.merge("#{param_name}": param_value)
      end
    end
  end

end
