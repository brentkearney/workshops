# config/initializers/griddler.rb

Griddler.configure do |config|
  config.email_service = :sparkpost
  config.processor_class = Maillists
end

