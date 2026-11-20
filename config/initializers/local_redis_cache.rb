require Rails.root.join("lib/local_redis/metrics")

# No-op outside the web runtime: non-web processes retain RedisCacheStore.
LocalRedis::Metrics.install(Rails.cache, stats_client: ForemStatsClient)
