require "logger"
require "redis-client"
require_relative "cache"

module LocalRedis
  # One daemon per local Redis, independent of Rails/Puma and its worker forks.
  # RESP3 BCAST tracking covers expiry, eviction, flushes and old app versions.
  class Sync
    def initialize(local_url:, remote_url:, logger: Logger.new($stdout))
      raise ArgumentError, "An authoritative Redis URL is required" if remote_url.to_s.empty?
      if Cache.same_endpoint?(remote_url, local_url)
        raise ArgumentError, "Local and authoritative Redis must be separate"
      end

      @cache = Cache.new(url: local_url, source_url: remote_url)
      @remote_url = remote_url
      @logger = logger
    end

    def run
      loop do
        run_once
      rescue Redis::BaseError, RedisClient::Error, ConnectionPool::Error, ConnectionPool::TimeoutError => e
        @logger.warn("LocalRedis sync disconnected (#{e.class}); using authoritative cache")
        sleep 1
      end
    end

    def run_once
      @cache.disable
      client = RedisClient.config(url: @remote_url, protocol: 3, timeout: 1, reconnect_attempts: false).new_client
      # PubSub exposes ordered RESP3 push frames and never silently reconnects.
      stream = client.pubsub
      stream.call("CLIENT", "TRACKING", "ON", "BCAST")
      response = stream.next_event(1)
      raise RedisClient::ConnectionError, "Tracking was not acknowledged" unless response == "OK"

      @cache.invalidate(nil)
      receive(stream)
    ensure
      stream&.close
      client&.close
      begin
        @cache.disable
      rescue Redis::BaseError, ConnectionPool::Error, ConnectionPool::TimeoutError
        # A dead daemon's lease expires even when its local Redis is unreachable.
      end
    end

    private

    def receive(stream)
      next_ping = 0
      pending = nil
      loop do
        now = Cache.monotonic_time
        raise RedisClient::ConnectionError, "Tracking heartbeat timed out" if pending && now - pending >= 2

        if pending.nil? && now >= next_ping
          pending = now
          next_ping = now + 1
          stream.call("PING", pending.to_s)
        end
        event = stream.next_event((next_ping - now).clamp(0.1, 1))
        if event.is_a?(Array) && event.first == "invalidate"
          @cache.invalidate(event[1])
        elsif pending && event == pending.to_s
          @cache.heartbeat(event)
          pending = nil
        elsif event.is_a?(RedisClient::Error)
          raise event
        end
      end
    end
  end
end
