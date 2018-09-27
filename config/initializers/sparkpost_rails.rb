# Defaults for SparkPost Gem (https://github.com/the-refinery/sparkpost_rails)
SparkPostRails.configure do |c|
  c.api_key = ENV['SPARKPOST_API_KEY']
  # c.sandbox = true                                # default: false
  # c.track_opens = true                            # default: false
  # c.track_clicks = true                           # default: false
  c.return_path = 'postmaster@birs.ca'            # default: nil
  # c.campaign_id = nil                             # default: nil
  # c.transactional = true                          # default: false
  # c.ip_pool = nil                                 # default: nil
  # c.inline_css = true                             # default: false
  # c.html_content_only = false                     # default: false
  # c.subaccount = nil                              # default: nil
end

ActionMailer::DeliveryJob.rescue_from(SparkPostRails::DeliveryException) do |exception|
  StaffMailer.notify_sysadmin(nil, exception)
end
