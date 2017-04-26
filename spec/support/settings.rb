# Load default settings for
require 'rails-settings-cached'

def setup
  Rails.cache.clear
  load "#{Rails.root}/config/initializers/settings.rb"
end

def teardown
  Setting.destroy_all
  Rails.cache.clear
end
