require "database_cleaner-active_record"

RSpec.configure do |config|
  config.after(:each, db_strategy: :truncation) do |_example|
    DatabaseCleaner.clean_with(:truncation)
  end
end
