require "capybara/rspec"
Capybara.default_host = 'http://localhost:3000'
Capybara.asset_host = 'http://localhost:3000'

# Access session variables via rack_session_access gem
#require "rack_session_access/capybara"