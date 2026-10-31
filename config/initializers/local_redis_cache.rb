require Rails.root.join("lib/local_redis/metrics")

# No-op unless LOCAL_REDIS_URL selected the local cache store in production.rb.
LocalRedis::Metrics.install(Rails.cache, stats_client: ForemStatsClient)
