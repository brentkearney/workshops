# config/initializers/griddler.rb


# Add Mailgun recipient param to @email[:recipient]. In some
# cases, Mailgun will POST with a different To: address than
# the actual intended recipient. For example, if the original
# email had To: custom-maillist@workshops.birs.ca, where
# "custom-maillist" is a Mailgun-hosted mail list that contains
# legit Workshops mail list addresses, i.e. 20w5014-invited@...
# This will add the legit Workshops address to params[:recipient]
# Code from: https://github.com/jwkratz/griddler-stripped-text
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

