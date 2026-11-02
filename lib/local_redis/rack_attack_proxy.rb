require "rack/attack/store_proxy/redis_cache_store_proxy"
require_relative "../active_support/cache/local_redis_cache_store"

module LocalRedis
  # Rack::Attack 6.8 selects its Redis adapter by exact class name, so it does
  # not recognize RedisCacheStore subclasses without an explicit adapter.
  class RackAttackProxy < Rack::Attack::StoreProxy::RedisCacheStoreProxy
    def self.handle?(store)
      store.is_a?(ActiveSupport::Cache::LocalRedisCacheStore)
    end
  end
end
