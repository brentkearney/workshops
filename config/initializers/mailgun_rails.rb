# Configuration for the Mailgun gem
# https://github.com/mailgun/mailgun-ruby

# Actionmailer config is in production.rb

Mailgun.configure do |config|
  config.api_key = ENV['MAILGUN_API_KEY'],
  config.domain = ENV['EMAIL_DOMAIN']
end

# ActionMailer::DeliveryJob.rescue_from(Mailgun::DeliveryException) do |exception|
#   StaffMailer.notify_sysadmin(nil, exception)
# end
