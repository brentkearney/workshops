# RailsSettings Model
class Setting < RailsSettings::Base
  attr_accessor :new_field, :new_value
  namespace Rails.env

end
