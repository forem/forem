# spec/lib/memory_first_cache_spec.rb
require 'rails_helper'
require 'memory_first_cache'

RSpec.describe MemoryFirstCache do
  let(:redis_key) { "test_redis_key" }
  let(:memory_key) { "memory_first:#{redis_key}" }
  let(:test_value) { "test_value" }
  let(:computed_value) { "computed_value" }
  let(:memory_store) { instance_double(ActiveSupport::Cache::MemoryStore) }
  let(:rails_cache) { instance_double(ActiveSupport::Cache::Store) }

  before do
    # Mock Rails.cache to use our test double
    allow(Rails).to receive(:cache).and_return(rails_cache)
    
    # Mock the memory store instance
    allow(described_class).to receive(:memory_store).and_return(memory_store)
    
    # Set up expectations for clear method
    allow(memory_store).to receive(:clear)
    
    # Allow Rails cache to handle any unexpected calls during test setup
    allow(rails_cache).to receive(:delete).with(any_args)
    allow(rails_cache).to receive(:read).with(any_args)
    allow(rails_cache).to receive(:write).with(any_args)
    
    # Clear any existing state
    described_class.clear
  end

  describe ".fetch" do
    context "when value exists in memory store" do
      it "returns the value from memory store without checking Redis" do
        expect(memory_store).to receive(:read).with(memory_key).and_return(test_value)
        expect(rails_cache).not_to receive(:read)

        result = described_class.fetch(redis_key)
        expect(result).to eq(test_value)
      end
    end

    context "when value exists in Redis but not in memory" do
      it "returns the value from Redis and backfills memory store" do
        expect(memory_store).to receive(:read).with(memory_key).and_return(nil)
        expect(rails_cache).to receive(:read).with(redis_key).and_return(test_value)
        expect(memory_store).to receive(:write).with(memory_key, test_value, expires_in: described_class::DEFAULT_MEMORY_EXPIRES_IN)

        result = described_class.fetch(redis_key)
        expect(result).to eq(test_value)
      end

      it "uses custom memory expiration when provided" do
        custom_memory_expires_in = 5.minutes
        
        expect(memory_store).to receive(:read).with(memory_key).and_return(nil)
        expect(rails_cache).to receive(:read).with(redis_key).and_return(test_value)
        expect(memory_store).to receive(:write).with(memory_key, test_value, expires_in: custom_memory_expires_in)

        result = described_class.fetch(redis_key, memory_expires_in: custom_memory_expires_in)
        expect(result).to eq(test_value)
      end
    end

    context "when value exists in neither store and block is provided" do
      it "executes the block and stores result in both stores" do
        expect(memory_store).to receive(:read).with(memory_key).and_return(nil)
        expect(rails_cache).to receive(:read).with(redis_key).and_return(nil)
        expect(rails_cache).to receive(:write).with(redis_key, computed_value)
        expect(memory_store).to receive(:write).with(memory_key, computed_value, expires_in: described_class::DEFAULT_MEMORY_EXPIRES_IN)

        result = described_class.fetch(redis_key) { computed_value }
        expect(result).to eq(computed_value)
      end

      it "uses custom Redis expiration when provided" do
        custom_redis_expires_in = 1.hour
        
        expect(memory_store).to receive(:read).with(memory_key).and_return(nil)
        expect(rails_cache).to receive(:read).with(redis_key).and_return(nil)
        expect(rails_cache).to receive(:write).with(redis_key, computed_value, expires_in: custom_redis_expires_in)
        expect(memory_store).to receive(:write).with(memory_key, computed_value, expires_in: described_class::DEFAULT_MEMORY_EXPIRES_IN)

        result = described_class.fetch(redis_key, redis_expires_in: custom_redis_expires_in) { computed_value }
        expect(result).to eq(computed_value)
      end

      it "uses default Rails cache behavior when no Redis expiration provided" do
        expect(memory_store).to receive(:read).with(memory_key).and_return(nil)
        expect(rails_cache).to receive(:read).with(redis_key).and_return(nil)
        expect(rails_cache).to receive(:write).with(redis_key, computed_value)
        expect(memory_store).to receive(:write).with(memory_key, computed_value, expires_in: described_class::DEFAULT_MEMORY_EXPIRES_IN)

        result = described_class.fetch(redis_key) { computed_value }
        expect(result).to eq(computed_value)
      end
    end

    context "when value exists in neither store and no block is provided" do
      it "returns nil" do
        expect(memory_store).to receive(:read).with(memory_key).and_return(nil)
        expect(rails_cache).to receive(:read).with(redis_key).and_return(nil)

        result = described_class.fetch(redis_key)
        expect(result).to be_nil
      end
    end

    context "with complex data types" do
      let(:complex_value) { { "key" => "value", "array" => [1, 2, 3], "nested" => { "inner" => "data" } } }

      it "handles complex objects correctly" do
        expect(memory_store).to receive(:read).with(memory_key).and_return(nil)
        expect(rails_cache).to receive(:read).with(redis_key).and_return(complex_value)
        expect(memory_store).to receive(:write).with(memory_key, complex_value, expires_in: described_class::DEFAULT_MEMORY_EXPIRES_IN)

        result = described_class.fetch(redis_key)
        expect(result).to eq(complex_value)
      end
    end

    context "with nil values" do
      it "handles nil values correctly in memory store" do
        expect(memory_store).to receive(:read).with(memory_key).and_return(nil)
        expect(rails_cache).to receive(:read).with(redis_key).and_return(nil)

        result = described_class.fetch(redis_key)
        expect(result).to be_nil
      end

      it "handles nil values correctly when computed from block" do
        expect(memory_store).to receive(:read).with(memory_key).and_return(nil)
        expect(rails_cache).to receive(:read).with(redis_key).and_return(nil)
        expect(rails_cache).to receive(:write).with(redis_key, nil)
        expect(memory_store).to receive(:write).with(memory_key, nil, expires_in: described_class::DEFAULT_MEMORY_EXPIRES_IN)

        result = described_class.fetch(redis_key) { nil }
        expect(result).to be_nil
      end
    end

    context "with false values" do
      it "handles false values correctly" do
        expect(memory_store).to receive(:read).with(memory_key).and_return(nil)
        expect(rails_cache).to receive(:read).with(redis_key).and_return(false)
        expect(memory_store).to receive(:write).with(memory_key, false, expires_in: described_class::DEFAULT_MEMORY_EXPIRES_IN)

        result = described_class.fetch(redis_key)
        expect(result).to be(false)
      end
    end
  end

  describe ".delete" do
    it "deletes from both memory store and Rails cache" do
      expect(memory_store).to receive(:delete).with(memory_key)
      expect(rails_cache).to receive(:delete).with(redis_key)

      described_class.delete(redis_key)
    end
  end

  describe ".clear" do
    it "clears the memory store" do
      # The memory store is already mocked in the before block
      expect(memory_store).to receive(:clear)

      described_class.clear
    end
  end


  describe "memory key generation" do
    it "generates correct memory key format" do
      expect(described_class.send(:memory_key_for, "test_key")).to eq("memory_first:test_key")
    end
  end

  describe "memory store initialization" do
    it "creates a memory store with default expiration" do
      # Reset the memory store to test initialization
      described_class.instance_variable_set(:@memory_store, nil)
      
      # Temporarily remove the mock for this test
      allow(described_class).to receive(:memory_store).and_call_original
      
      expect(ActiveSupport::Cache::MemoryStore).to receive(:new).with(expires_in: described_class::DEFAULT_MEMORY_EXPIRES_IN)
      described_class.send(:memory_store)
    end
  end

  describe "integration scenarios" do
    let(:real_memory_store) { ActiveSupport::Cache::MemoryStore.new }
    let(:real_rails_cache) { ActiveSupport::Cache::MemoryStore.new }

    before do
      # Use real cache stores for integration testing
      allow(described_class).to receive(:memory_store).and_return(real_memory_store)
      allow(Rails).to receive(:cache).and_return(real_rails_cache)
    end

    after do
      real_memory_store.clear
      real_rails_cache.clear
    end

    it "performs complete cache flow: miss -> compute -> store -> hit" do
      # First call should miss both stores and compute
      result1 = described_class.fetch(redis_key) { computed_value }
      expect(result1).to eq(computed_value)

      # Second call should hit memory store
      result2 = described_class.fetch(redis_key)
      expect(result2).to eq(computed_value)

      # Clear memory store to test Redis fallback
      real_memory_store.clear

      # Third call should hit Redis and backfill memory
      result3 = described_class.fetch(redis_key)
      expect(result3).to eq(computed_value)

      # Fourth call should hit memory store again
      result4 = described_class.fetch(redis_key)
      expect(result4).to eq(computed_value)
    end

    it "handles expiration correctly" do
      # Store with short expiration
      described_class.fetch(redis_key, memory_expires_in: 1.second) { computed_value }
      
      # Should be available immediately
      expect(described_class.fetch(redis_key)).to eq(computed_value)
      
      # Wait for expiration
      sleep(1.1)
      
      # Should fall back to Redis
      expect(described_class.fetch(redis_key)).to eq(computed_value)
    end

    it "handles concurrent access correctly" do
      # Simulate concurrent access by multiple threads
      threads = []
      results = []
      
      5.times do |i|
        threads << Thread.new do
          result = described_class.fetch("#{redis_key}_#{i}") { "value_#{i}" }
          results << result
        end
      end
      
      threads.each(&:join)
      
      expect(results).to contain_exactly("value_0", "value_1", "value_2", "value_3", "value_4")
    end
  end

  describe "error handling" do
    it "handles memory store errors gracefully" do
      allow(memory_store).to receive(:read).and_raise(StandardError.new("Memory store error"))
      
      expect { described_class.fetch(redis_key) }.to raise_error(StandardError, "Memory store error")
    end

    it "handles Rails cache errors gracefully" do
      allow(memory_store).to receive(:read).and_return(nil)
      allow(rails_cache).to receive(:read).and_raise(StandardError.new("Rails cache error"))
      
      expect { described_class.fetch(redis_key) }.to raise_error(StandardError, "Rails cache error")
    end

    it "handles block execution errors" do
      allow(memory_store).to receive(:read).and_return(nil)
      allow(rails_cache).to receive(:read).and_return(nil)
      
      expect { described_class.fetch(redis_key) { raise StandardError.new("Block error") } }
        .to raise_error(StandardError, "Block error")
    end
  end

  describe "return_type conversion" do
    it "converts to integer type correctly" do
      expect(memory_store).to receive(:read).with(memory_key).and_return(nil)
      expect(rails_cache).to receive(:read).with(redis_key).and_return(nil)
      expect(rails_cache).to receive(:write).with(redis_key, 42)
      expect(memory_store).to receive(:write).with(memory_key, 42, expires_in: described_class::DEFAULT_MEMORY_EXPIRES_IN)
      
      result = described_class.fetch(redis_key, return_type: :integer) { 42 }
      expect(result).to eq(42)
    end

    it "handles nil values with integer type" do
      expect(memory_store).to receive(:read).with(memory_key).and_return(nil)
      expect(rails_cache).to receive(:read).with(redis_key).and_return(nil)
      expect(rails_cache).to receive(:write).with(redis_key, nil)
      expect(memory_store).to receive(:write).with(memory_key, nil, expires_in: described_class::DEFAULT_MEMORY_EXPIRES_IN)
      
      result = described_class.fetch(redis_key, return_type: :integer) { nil }
      expect(result).to be_nil
    end

    it "handles empty string with integer type" do
      expect(memory_store).to receive(:read).with(memory_key).and_return(nil)
      expect(rails_cache).to receive(:read).with(redis_key).and_return(nil)
      expect(rails_cache).to receive(:write).with(redis_key, "")
      expect(memory_store).to receive(:write).with(memory_key, "", expires_in: described_class::DEFAULT_MEMORY_EXPIRES_IN)
      
      result = described_class.fetch(redis_key, return_type: :integer) { "" }
      expect(result).to be_nil
    end

    it "converts to boolean type correctly" do
      expect(memory_store).to receive(:read).with(memory_key).and_return(nil)
      expect(rails_cache).to receive(:read).with(redis_key).and_return(nil)
      expect(rails_cache).to receive(:write).with(redis_key, "true")
      expect(memory_store).to receive(:write).with(memory_key, "true", expires_in: described_class::DEFAULT_MEMORY_EXPIRES_IN)
      
      result = described_class.fetch(redis_key, return_type: :boolean) { "true" }
      expect(result).to be(true)
    end

    it "converts to string type correctly" do
      expect(memory_store).to receive(:read).with(memory_key).and_return(nil)
      expect(rails_cache).to receive(:read).with(redis_key).and_return(nil)
      expect(rails_cache).to receive(:write).with(redis_key, 42)
      expect(memory_store).to receive(:write).with(memory_key, 42, expires_in: described_class::DEFAULT_MEMORY_EXPIRES_IN)
      
      result = described_class.fetch(redis_key, return_type: :string) { 42 }
      expect(result).to eq("42")
    end
  end

  describe "performance characteristics" do
    it "memory store is faster than Redis for repeated reads" do
      # This is more of a behavioral test than a performance test
      # but it verifies the intended optimization
      
      # First call: miss memory, miss Redis, compute and store
      expect(memory_store).to receive(:read).with(memory_key).and_return(nil)
      expect(rails_cache).to receive(:read).with(redis_key).and_return(nil)
      expect(rails_cache).to receive(:write).with(redis_key, computed_value)
      expect(memory_store).to receive(:write).with(memory_key, computed_value, expires_in: described_class::DEFAULT_MEMORY_EXPIRES_IN)
      
      described_class.fetch(redis_key) { computed_value }
      
      # Second call: hit memory store, no Redis call
      expect(memory_store).to receive(:read).with(memory_key).and_return(computed_value)
      expect(rails_cache).not_to receive(:read)
      
      described_class.fetch(redis_key)
    end
  end
end
