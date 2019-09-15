# config/initializers/griddler.rb

Griddler.configure do |config|
  config.email_service = :mailgun
  config.processor_class = EmailProcessor
  config.processor_method = :process
end

