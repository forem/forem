RSpec.configure do |config|
  config.after(:each, db_strategy: :truncation) do |_example|
    ActiveRecord::Tasks::DatabaseTasks.truncate_all
    User.count
  end
end
