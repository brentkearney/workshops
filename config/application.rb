require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Workshops
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Configuration for the "Global" settings gem
    Global.configure do |c|
      c.environment = Rails.env.to_s
      c.config_directory = Rails.root.join('config/settings').to_s
    end

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    #config.time_zone = 'Mountain Time (US & Canada)'
    #config.active_record.default_timezone = :local

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # Serve error pages with Rails
    config.exceptions_app = self.routes
    
    # Use RSpec & FactoryGirl
    config.generators do |g| 
      g.test_framework :rspec, 
        :fixtures => true, 
        :view_specs => false, 
        :helper_specs => false, 
        :routing_specs => false, 
        :controller_specs => true, 
        :request_specs => true 
      g.fixture_replacement :factory_girl, :dir => "spec/factories" 
    end

    # Load environment variables
    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'local_env.yml')
      YAML.load(File.open(env_file)).each do |key, value|
        ENV[key.to_s] = value
      end if File.exists?(env_file)
    end
    
  end
end

