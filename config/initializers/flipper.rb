Flipper.configure do |config|
  # Share a process-wide thread-safe MemoryStore (keyed by TTL) across all threads
  # instead of allocating a cold MemoryStore per thread via `Thread.current[:flipper_instance]`.
  memory_stores = Concurrent::Map.new

  config.default do
    adapter = if (cache_duration = ENV.fetch("CACHE_FEATURE_FLAGS_SECONDS", nil))
                ttl = cache_duration.to_i.seconds
                cache_store = memory_stores.compute_if_absent(ttl.to_i) do
                  ActiveSupport::Cache::MemoryStore.new(expires_in: ttl)
                end
                Flipper::Adapters::ActiveSupportCacheStore.new(
                  Flipper::Adapters::ActiveRecord.new,
                  cache_store,
                )
              else
                Flipper::Adapters::ActiveRecord.new
              end

    # pass adapter to handy DSL instance
    Flipper.new(adapter)
  end
end
