RSpec.configure do |config|
  config.before do
    # Clear the memory store between tests to prevent leakage
    # Skip for MemoryFirstCache tests to avoid interfering with their mocks
    unless RSpec.current_example&.file_path&.include?("memory_first_cache_spec.rb")
      MemoryFirstCache.reset_memory_store!
    end
  end

  config.after do
    # Ensure cleanup after each test
    # Skip for MemoryFirstCache tests to avoid interfering with their mocks
    unless RSpec.current_example&.file_path&.include?("memory_first_cache_spec.rb")
      MemoryFirstCache.reset_memory_store!
    end
  end

  # Also clear before test suites to ensure clean state
  config.before(:suite) do
    MemoryFirstCache.reset_memory_store!
  end

  config.after(:suite) do
    MemoryFirstCache.reset_memory_store!
  end
end
