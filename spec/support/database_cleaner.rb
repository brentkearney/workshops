require 'database_cleaner'
ENV["RAILS_ENV"] ||= 'test'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation, pre_count: true, reset_ids: true)
  end

  config.before(:each) do
    # DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
    ActiveRecord::Base.connection.reset_pk_sequence!('events')
  end
end
