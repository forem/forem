require "redis"
require "connection_pool"
require "securerandom"
require "uri"
require "digest"
require "zlib"

module LocalRedis
  # This Redis database is disposable and must be dedicated to this cache.
  # Scripts operate on serialized Rails entries, without interpreting their format.
  class Cache
    LEASE_KEY = "forem:l1:lease".freeze
    GUARDS_KEY = "forem:l1:guards".freeze
    DATA_PREFIX = "forem:l1:data:".freeze
    LEASE_MS = 3000
    DEFAULT_MAX_TTL_SECONDS = 30
    HARD_MAX_TTL_SECONDS = 600
    # Fills are guarded per key bucket, so invalidations of unrelated keys during a
    # hosted round trip do not discard the fill. Collisions only cost a miss.
    GUARD_BUCKETS = 4096

    # KEYS: lease, guards, data keys. ARGV: each data key's guard bucket.
    # Returns {} without a lease, else {lease, values..., guard tokens...}.
    READ = <<~LUA.freeze
      local lease = redis.call('GET', KEYS[1])
      if not lease or redis.call('HGET', KEYS[2], 'epoch') ~= lease then return {} end
      local count = #KEYS - 2
      local result = {lease}
      for i = 1, count do
        result[i + 1] = redis.call('GET', KEYS[i + 2])
        result[count + i + 1] = redis.call('HGET', KEYS[2], ARGV[i]) or ''
      end
      return result
    LUA

    # ARGV: generation, then bucket, guard token, payload, ttl for each data key.
    # Each key fills only if no invalidation touched its bucket since the read.
    FILL = <<~LUA.freeze
      if redis.call('GET', KEYS[1]) ~= ARGV[1] or redis.call('HGET', KEYS[2], 'epoch') ~= ARGV[1] then
        return 0
      end
      local filled = 0
      for i = 3, #KEYS do
        local arg = 2 + (i - 3) * 4
        local ttl = tonumber(ARGV[arg + 3])
        if ttl > 0 and (redis.call('HGET', KEYS[2], ARGV[arg]) or '') == ARGV[arg + 1] then
          redis.call('SET', KEYS[i], ARGV[arg + 2], 'PX', ttl)
          filled = filled + 1
        end
      end
      return filled
    LUA

    # ARGV: a fresh random token, then each data key's guard bucket.
    INVALIDATE = <<~LUA.freeze
      for i = 3, #KEYS do
        redis.call('HSET', KEYS[2], ARGV[i - 1], ARGV[1])
        redis.call('DEL', KEYS[i])
      end
    LUA

    # A missing lease or guard epoch (expiry, eviction, flush) resets L1 under a
    # new generation. Keys created after FLUSHDB ASYNC are not removed by it.
    HEARTBEAT = <<~LUA.freeze
      local lease = redis.call('GET', KEYS[1])
      if not lease or redis.call('HGET', KEYS[2], 'epoch') ~= lease then
        redis.call('FLUSHDB', 'ASYNC')
        redis.call('SET', KEYS[1], ARGV[1])
        redis.call('HSET', KEYS[2], 'epoch', ARGV[1])
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

    def self.max_ttl_ms
      value = ENV.fetch("LOCAL_REDIS_MAX_TTL", DEFAULT_MAX_TTL_SECONDS.to_s)
      unless value.match?(/\A[1-9]\d*\z/) && value.to_i <= HARD_MAX_TTL_SECONDS
        raise ArgumentError, "LOCAL_REDIS_MAX_TTL must be whole seconds between 1 and #{HARD_MAX_TTL_SECONDS}"
      end

      value.to_i * 1000
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

    attr_reader :lease_key, :guards_key, :data_prefix

    def initialize(url:, source_url:)
      self.class.socket_path(url)
      origin = Digest::SHA256.hexdigest(source_url)
      @lease_key = "#{LEASE_KEY}:#{origin}"
      @guards_key = "#{GUARDS_KEY}:#{origin}"
      @data_prefix = "#{DATA_PREFIX}#{origin}:"
      @pool = ConnectionPool.new(size: 5, timeout: 0.05) do
        Redis.new(url: url, connect_timeout: 0.05, read_timeout: 0.05, write_timeout: 0.05,
                  reconnect_attempts: 0)
      end
    end

    # Returns nil when L1 is disabled, else [generation, values, guard tokens].
    def read(keys)
      reply = @pool.with { |client| client.eval(READ, keys: local_keys(keys), argv: buckets(keys)) }
      return if reply.empty?

      [reply.first, reply[1, keys.size], reply[(keys.size + 1)..]]
    end

    # entries: { key => [payload, ttl_ms] }; guards: { key => token from read }.
    def fill(generation, entries, guards)
      return if entries.empty?

      argv = entries.flat_map do |key, (payload, ttl)|
        [bucket(key), guards.fetch(key), payload, ttl]
      end
      @pool.with { |client| client.eval(FILL, keys: local_keys(entries.keys), argv: [generation, *argv]) }
    end

    def invalidate(keys)
      @pool.with do |client|
        if keys.nil?
          client.flushdb(async: true)
        else
          client.eval(INVALIDATE, keys: local_keys(keys), argv: [SecureRandom.hex(8), *buckets(keys)])
        end
      end
    end

    def heartbeat(sent_at)
      remaining = LEASE_MS - ((self.class.monotonic_time - Float(sent_at)) * 1000).ceil
      return if remaining <= 0 || remaining > LEASE_MS

      @pool.with do |client|
        client.eval(HEARTBEAT, keys: [lease_key, guards_key], argv: [SecureRandom.hex(16), remaining])
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
      [lease_key, guards_key, *keys.map { |key| "#{data_prefix}#{key}" }]
    end

    def buckets(keys)
      keys.map { |key| bucket(key) }
    end

    def bucket(key)
      Zlib.crc32(key) % GUARD_BUCKETS
    end
  end
end
