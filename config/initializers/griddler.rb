# config/initializers/griddler.rb


# Add Mailgun recipient param to @email[:recipient], for delivery
# from maillists that contain @workshops addresses
# https://github.com/jwkratz/griddler-stripped-text
module GriddlerMailgunAdapterExtensions
  def normalize_params
    normalized_params = super
    normalized_params[:recipient] = params['recipient']
    normalized_params
  end
end

# Prepend custom extensions
Griddler::Mailgun::Adapter.class_eval do
  prepend GriddlerMailgunAdapterExtensions
end

# Assign Mailgun stripped-text to attribute
module GriddlerEmailExtensions
  def initialize(params)
    super
    @recipient = params[:recipient]
  end
end

# Add attribute for Mailgun recipient and prepend custom extensions
Griddler::Email.class_eval do
  attr_reader :recipient
  prepend GriddlerEmailExtensions
end

Griddler.configure do |config|
  config.email_service = :mailgun
  config.processor_class = EmailProcessor
  config.processor_method = :process
end

