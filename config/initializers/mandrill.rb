# Connect to Mailchimp/Mandrill API for transactional emails
MandrillMailer.configure do |config|
  config.api_key = ENV['MANDRILL_API_KEY']
  config.deliver_later_queue_name = :default
end
