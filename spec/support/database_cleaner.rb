require 'database_cleaner'

RSpec.configure do |config|
  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation, { except: %w[Setting] }
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:deletion)
  end

  config.before :each do
    if Capybara.current_driver == :rack_test
      DatabaseCleaner.strategy = :transaction
    else
      DatabaseCleaner.strategy = :deletion
    end

    DatabaseCleaner.start
  end

  config.after(:each)  { DatabaseCleaner.clean }

  config.after(:suite) do
    DatabaseCleaner.clean_with(:deletion)
  end
end
