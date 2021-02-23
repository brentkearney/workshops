# Mailjet Templates
# https://github.com/mailjet/mailjet-gem

# initializers/mailjet.rb
Mailjet.configure do |config|
  config.api_key = ENV['MAILJET_API_KEY']
  config.secret_key = ENV['MAILJET_SECRET_KEY']
  config.default_from = ENV['MAILJET_DEFAULT_FROM']
  config.api_version = "v3.1"
end
