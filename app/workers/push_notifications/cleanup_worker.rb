module PushNotifications
  class CleanupWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 10

    def perform
      redis = Redis.new
      redis.keys("rpush:notifications:*").each do |key|
        next unless redis.ttl(key) == -1
        next unless redis.type(key) == "hash"
        next if redis.hget(key, "delivered").nil?

        redis.expire(key, 8.hours.to_i)
      end
    end
  end
end
