# Load default settings for
require 'rails-settings-cached'
load "#{Rails.root}/config/initializers/settings.rb"

def setup
  Rails.cache.clear
end

def teardown
  Rails.cache.clear
end
