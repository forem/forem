require "redis"
require "connection_pool"
require "securerandom"
require "uri"
require "digest"

module LocalRedis
  # This Redis database is disposable and must be dedicated to this cache.
  # Scripts operate on serialized Rails entries, without interpreting their format.
  class Cache
    LEASE_KEY = "forem:l1:lease".freeze
    DATA_PREFIX = "forem:l1:data:".freeze
    LEASE_MS = 3000
    MAX_TTL_MS = 30_000

    READ = <<~LUA.freeze
      local lease = redis.call('GET', KEYS[1])
      if not lease then return {} end
      local result = {lease}
      for i = 2, #KEYS do
        result[i] = redis.call('GET', KEYS[i])
      end
      return result
    LUA

    FILL = <<~LUA.freeze
      if redis.call('GET', KEYS[1]) ~= ARGV[1] then return 0 end
      for i = 2, #KEYS do
        local ttl = tonumber(ARGV[2 * i - 1])
        if ttl > 0 then
          redis.call('SET', KEYS[i], ARGV[2 * i - 2], 'PX', ttl)
        end
      end
      return 1
    LUA

    INVALIDATE = <<~LUA.freeze
      local ttl = redis.call('PTTL', KEYS[1])
      if ttl > 0 then redis.call('SET', KEYS[1], ARGV[1], 'PX', ttl) end
      for i = 2, #KEYS do redis.call('DEL', KEYS[i]) end
    LUA

    HEARTBEAT = <<~LUA.freeze
      if not redis.call('GET', KEYS[1]) then
        redis.call('FLUSHDB', 'ASYNC')
        redis.call('SET', KEYS[1], ARGV[1])
      end
      redis.call('PEXPIRE', KEYS[1], ARGV[2])
    LUA

    def self.socket_path(url)
      uri = URI.parse(url)
      unless uri.scheme == "unix" && uri.host.to_s.empty? && uri.path.to_s.start_with?("/") &&
          uri.query.nil? && uri.fragment.nil? && uri.userinfo.nil?
        raise ArgumentError, "LOCAL_REDIS_URL must be an absolute unix:///path socket URL"
      end

      uri.path
    end

    def self.monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def self.same_endpoint?(source_url, local_url)
      source = URI.parse(source_url)
      return false if source.scheme != "unix" || source.path.to_s.empty?

      local = socket_path(local_url)
      # identical? also catches hard links and bind mounts of an existing socket.
      canonical_socket_path(source.path) == canonical_socket_path(local) || File.identical?(source.path, local)
    end

    def self.canonical_socket_path(path)
      # Resolve socket and directory symlinks, even before Redis creates the socket.
      File.realdirpath(path)
    rescue SystemCallError
      # Resolve the nearest existing ancestor so aliases such as /tmp still match.
      expanded = File.expand_path(path)
      parent = File.dirname(expanded)
      parent == expanded ? expanded : File.join(canonical_socket_path(parent), File.basename(expanded))
    end
    private_class_method :canonical_socket_path

    attr_reader :lease_key, :data_prefix

    def initialize(url:, source_url:)
      self.class.socket_path(url)
      origin = Digest::SHA256.hexdigest(source_url)
      @lease_key = "#{LEASE_KEY}:#{origin}"
      @data_prefix = "#{DATA_PREFIX}#{origin}:"
      @pool = ConnectionPool.new(size: 5, timeout: 0.05) do
        Redis.new(url: url, connect_timeout: 0.05, read_timeout: 0.05, write_timeout: 0.05,
                  reconnect_attempts: 0)
      end
    end

    def read(keys)
      @pool.with { |client| client.eval(READ, keys: local_keys(keys)) }
    end

    def fill(generation, entries)
      return if entries.empty?

      @pool.with do |client|
        client.eval(FILL, keys: local_keys(entries.keys), argv: [generation, *entries.values.flatten(1)])
      end
    end

    def invalidate(keys)
      @pool.with do |client|
        if keys.nil?
          client.flushdb(async: true)
        else
          client.eval(INVALIDATE, keys: local_keys(keys), argv: [SecureRandom.hex(16)])
        end
      end
    end

    def heartbeat(sent_at)
      remaining = LEASE_MS - ((self.class.monotonic_time - Float(sent_at)) * 1000).ceil
      return if remaining <= 0 || remaining > LEASE_MS

      @pool.with do |client|
        client.eval(HEARTBEAT, keys: [lease_key], argv: [SecureRandom.hex(16), remaining])
      end
    end

    def disable
      @pool.with { |client| client.del(lease_key) }
    end

    def close
      @pool.shutdown(&:close)
    end

    private

    def local_keys(keys)
      [lease_key, *keys.map { |key| "#{data_prefix}#{key}" }]
    end
  end
end
