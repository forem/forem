# Helpers to reduce flakiness in tests
module FlakyTestHelpers
  # Wait for a condition to be true with a timeout
  def wait_for_condition(timeout: 10, &block)
    Timeout.timeout(timeout) do
      loop do
        break if block.call
        sleep 0.1
      end
    end
  rescue Timeout::Error
    raise "Condition not met within #{timeout} seconds"
  end

  # Retry a block of code on flaky failures
  def retry_on_flaky_failure(retries: 3, wait: 1)
    attempts = 0
    begin
      attempts += 1
      yield
    rescue RSpec::Expectations::ExpectationNotMetError, Capybara::ElementNotFound => e
      if attempts < retries
        sleep wait
        retry
      else
        raise e
      end
    end
  end

  # Ensure database state is consistent before running test
  def ensure_clean_database_state
    # Clear any leftover data that might interfere with tests
    ActiveRecord::Base.connection.truncate_tables(*ActiveRecord::Base.connection.tables - %w[ar_internal_metadata schema_migrations])
    
    # Reset auto-increment counters if needed
    if ActiveRecord::Base.connection.adapter_name.downcase.include?('mysql')
      ActiveRecord::Base.connection.tables.each do |table|
        ActiveRecord::Base.connection.execute("ALTER TABLE #{table} AUTO_INCREMENT = 1") rescue nil
      end
    end
  end

  # Stub time-based randomness for deterministic tests
  def with_deterministic_time(&block)
    travel_to(Time.zone.parse("2023-01-01 12:00:00"), &block)
  end

  # Stub random values for deterministic behavior
  def with_deterministic_randomness(seed: 12345, &block)
    srand(seed)
    yield
  ensure
    srand # Reset to random seed
  end
end

RSpec.configure do |config|
  config.include FlakyTestHelpers, type: :system
  config.include FlakyTestHelpers, type: :service
  config.include FlakyTestHelpers, type: :request
end