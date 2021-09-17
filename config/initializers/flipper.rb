Flipper.configure do |config|
  config.default do
    adapter = if (cache_duration = ENV["CACHE_FEATURE_FLAGS_SECONDS"])
                Flipper::Adapters::ActiveSupportCacheStore.new(
                  Flipper::Adapters::ActiveRecord.new,
                  ActiveSupport::Cache::MemoryStore.new(expires_in: cache_duration.to_i.seconds),
                )
              else
                Flipper::Adapters::ActiveRecord.new
              end

    # pass adapter to handy DSL instance
    Flipper.new(adapter)
  end
end
