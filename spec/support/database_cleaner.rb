require 'database_cleaner'
ENV["RAILS_ENV"] ||= 'test'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation, pre_count: true, reset_ids: true)
    DatabaseCleaner.start
    DatabaseCleaner.clean
  end

  config.before(:each) do
    DatabaseCleaner.clean
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.after(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end
end
