# RailsSettings Model
class Setting < RailsSettings::Base
  attr_accessor :new_field, :new_value
  before_save :convert_type
  namespace Rails.env

  def convert_type
    self.value.each do |field_name, field_value|
      if field_value =~ /^\[(.+)\]$/
        to_array(field_name, field_value)
      elsif field_value =~ /^{(.+)}$/
        to_hash(field_name, field_value)
      end
    end
  end

  def to_array(field_name, field_value)
    field_value = field_value.gsub(/^\[|"|\]$/, '').split(',').map(&:strip)
    self.value = self.value.merge("#{field_name}": field_value)
  end

  def to_hash(field_name, field_value)
    hash = {}
    field_value.gsub(/^{|}$/, '').split(',').each do |item|
      key, val = item.split(':').map(&:strip)
      hash[key] = val
    end
    self.value = self.value.merge("#{field_name}": hash)
  end
end
