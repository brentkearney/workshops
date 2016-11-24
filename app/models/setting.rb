# RailsSettings Model
class Setting < RailsSettings::Base
  attr_accessor :new_field, :new_value
  before_save :convert_type
  namespace Rails.env

  def convert_type
    self.value.each do |field_name, field_value|
      if field_value =~ /^\[(.+)\]$/
        field_value = field_value.gsub(/^\[|"|\]$/, '').split(',').map(&:strip)
        self.value = self.value.merge("#{field_name}": field_value)
      end
    end
  end
end
