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

  def organize_params
    @setting.value = update_params
  end

  def update_params
    data = @params.require(:setting).permit(@setting.var => valid_fields)
    data["#{@setting.var}"]
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
    @params['setting']['Locations'] ? [:new_location, :remove_location] : Array.new
  end
end
