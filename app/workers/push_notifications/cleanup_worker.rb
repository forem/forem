module PushNotifications
  class CleanupWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 10, lock: :until_and_while_executing

    def perform
      redis = Redis.new(url: ENV["REDIS_RPUSH_URL"] || ENV["REDIS_URL"])
      cursor = 0
      until (cursor, keys = redis.scan(cursor, match: "rpush:notifications:*")).first.to_i.zero?
        keys.each do |key|
          next unless redis.ttl(key) == -1
          next unless redis.type(key) == "hash"
          next if redis.hget(key, "delivered").nil?

          redis.expire(key, 8.hours.to_i)
        end
      end
    end
  end
end
