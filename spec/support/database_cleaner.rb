require 'database_cleaner'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation, { except: %w[Setting] }
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  # config.append_after(:each) do
  config.after(:each) do
    DatabaseCleaner.clean
  end
end
