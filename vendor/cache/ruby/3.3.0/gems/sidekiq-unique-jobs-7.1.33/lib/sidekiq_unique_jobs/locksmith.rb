# frozen_string_literal: true

module SidekiqUniqueJobs
  # Lock manager class that handles all the various locks
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  class Locksmith # rubocop:disable Metrics/ClassLength
    # includes "SidekiqUniqueJobs::Connection"
    # @!parse include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::Connection

    # includes "SidekiqUniqueJobs::Logging"
    # @!parse include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::Logging

    # includes "SidekiqUniqueJobs::Reflectable"
    # @!parse include SidekiqUniqueJobs::Reflectable
    include SidekiqUniqueJobs::Reflectable

    # includes "SidekiqUniqueJobs::Timing"
    # @!parse include SidekiqUniqueJobs::Timing
    include SidekiqUniqueJobs::Timing

    # includes "SidekiqUniqueJobs::Script::Caller"
    # @!parse include SidekiqUniqueJobs::Script::Caller
    include SidekiqUniqueJobs::Script::Caller

    # includes "SidekiqUniqueJobs::JSON"
    # @!parse include SidekiqUniqueJobs::JSON
    include SidekiqUniqueJobs::JSON

    #
    # @return [Float] used to take into consideration the inaccuracy of redis timestamps
    CLOCK_DRIFT_FACTOR = 0.01
    NETWORK_FACTOR = 0.04

    #
    # @!attribute [r] key
    #   @return [Key] the key used for locking
    attr_reader :key
    #
    # @!attribute [r] job_id
    #   @return [String] a sidekiq JID
    attr_reader :job_id
    #
    # @!attribute [r] config
    #   @return [LockConfig] the configuration for this lock
    attr_reader :config
    #
    # @!attribute [r] item
    #   @return [Hash] a sidekiq job hash
    attr_reader :item

    #
    # Initialize a new Locksmith instance
    #
    # @param [Hash] item a Sidekiq job hash
    # @option item [Integer] :lock_ttl the configured expiration
    # @option item [String] :jid the sidekiq job id
    # @option item [String] :unique_digest the unique digest (See: {LockDigest#lock_digest})
    # @param [Sidekiq::RedisConnection, ConnectionPool] redis_pool the redis connection
    #
    def initialize(item, redis_pool = nil)
      @item        = item
      @key         = Key.new(item[LOCK_DIGEST] || item[UNIQUE_DIGEST]) # fallback until can be removed
      @job_id      = item[JID]
      @config      = LockConfig.new(item)
      @redis_pool  = redis_pool
    end

    #
    # Deletes the lock unless it has a pttl set
    #
    #
    def delete
      return if config.pttl.positive?

      delete!
    end

    #
    # Deletes the lock regardless of if it has a pttl set
    #
    def delete!
      call_script(:delete, key.to_a, [job_id, config.pttl, config.type, config.limit]).to_i.positive?
    end

    #
    # Create a lock for the Sidekiq job
    #
    # @return [String] the Sidekiq job_id that was locked/queued
    #
    def lock(wait: nil)
      method_name = wait ? :primed_async : :primed_sync
      redis(redis_pool) do |conn|
        lock!(conn, method(method_name), wait) do
          return job_id
        end
      end
    end

    def execute(&block)
      raise SidekiqUniqueJobs::InvalidArgument, "#execute needs a block" unless block

      redis(redis_pool) do |conn|
        lock!(conn, method(:primed_async), &block)
      end
    end

    #
    # Removes the lock keys from Redis if locked by the provided jid/token
    #
    # @return [false] unless locked?
    # @return [String] Sidekiq job_id (jid) if successful
    #
    def unlock(conn = nil)
      return false unless locked?(conn)

      unlock!(conn)
    end

    #
    # Removes the lock keys from Redis
    #
    # @return [false] unless locked?
    # @return [String] Sidekiq job_id (jid) if successful
    #
    def unlock!(conn = nil)
      call_script(:unlock, key.to_a, argv, conn) do |unlocked_jid|
        if unlocked_jid == job_id
          reflect(:debug, :unlocked, item, unlocked_jid)
          reflect(:unlocked, item)
        end

        unlocked_jid
      end
    end

    # Checks if this instance is considered locked
    #
    # @param [Sidekiq::RedisConnection, ConnectionPool] conn the redis connection
    #
    # @return [true, false] true when the :LOCKED hash contains the job_id
    #
    def locked?(conn = nil)
      return taken?(conn) if conn

      redis { |rcon| taken?(rcon) }
    end

    #
    # Nicely formatted string with information about self
    #
    #
    # @return [String]
    #
    def to_s
      "Locksmith##{object_id}(digest=#{key} job_id=#{job_id} locked=#{locked?})"
    end

    #
    # @see to_s
    #
    def inspect
      to_s
    end

    #
    # Compare this locksmith with another
    #
    # @param [Locksmith] other the locksmith to compare with
    #
    # @return [true, false]
    #
    def ==(other)
      key == other.key && job_id == other.job_id
    end

    private

    attr_reader :redis_pool

    #
    # Used to reduce some duplication from the two methods
    #
    # @see lock
    # @see execute
    #
    # @param [Sidekiq::RedisConnection, ConnectionPool] conn the redis connection
    # @param [Method] primed_method reference to the method to use for getting a primed token
    # @param [nil, Integer, Float] time to wait before timeout
    #
    # @yieldparam [string] job_id the sidekiq JID
    # @yieldreturn [void] whatever the calling block returns
    def lock!(conn, primed_method, wait = nil)
      return yield if locked?(conn)

      enqueue(conn) do |queued_jid|
        reflect(:debug, :queued, item, queued_jid)

        primed_method.call(conn, wait) do |primed_jid|
          reflect(:debug, :primed, item, primed_jid)
          locked_jid = call_script(:lock, key.to_a, argv, conn)

          if locked_jid
            reflect(:debug, :locked, item, locked_jid)
            return yield
          end
        end
      end
    end

    #
    # Prepares all the various lock data
    #
    # @param [Redis] conn a redis connection
    #
    # @return [nil] when redis was already prepared for this lock
    # @return [yield<String>] when successfully enqueued
    #
    def enqueue(conn)
      queued_jid, elapsed = timed do
        call_script(:queue, key.to_a, argv, conn)
      end

      return unless queued_jid
      return unless [job_id, "1"].include?(queued_jid)

      validity = config.pttl - elapsed - drift(config.pttl)
      return unless validity >= 0 || config.pttl.zero?

      write_lock_info(conn)
      yield job_id
    end

    #
    # Pops an enqueued token
    # @note Used for runtime locks to avoid problems with blocking commands
    #   in current thread
    #
    # @param [Redis] conn a redis connection
    #
    # @return [nil] when lock was not possible
    # @return [Object] whatever the block returns when lock was acquired
    #
    def primed_async(conn, wait = nil, &block)
      timeout = (wait || config.timeout).to_i
      timeout = 1 if timeout.zero?

      brpoplpush_timeout = timeout
      concurrent_timeout = add_drift(timeout)

      reflect(:debug, :timeouts, item,
              timeouts: {
                brpoplpush_timeout: brpoplpush_timeout,
                concurrent_timeout: concurrent_timeout,
              })

      # NOTE: When debugging, change .value to .value!
      primed_jid = Concurrent::Promises
                   .future(conn) { |red_con| pop_queued(red_con, timeout) }
                   .value

      handle_primed(primed_jid, &block)
    end

    #
    # Pops an enqueued token
    # @note Used for non-runtime locks
    #
    # @param [Redis] conn a redis connection
    #
    # @return [nil] when lock was not possible
    # @return [Object] whatever the block returns when lock was acquired
    #
    def primed_sync(conn, wait = nil, &block)
      primed_jid = pop_queued(conn, wait)
      handle_primed(primed_jid, &block)
    end

    def handle_primed(primed_jid)
      return yield job_id if [job_id, "1"].include?(primed_jid)

      reflect(:timeout, item) unless config.wait_for_lock?
    end

    #
    # Does the actual popping of the enqueued token
    #
    # @param [Redis] conn a redis connection
    #
    # @return [String] a previously enqueued token (now taken off the queue)
    #
    def pop_queued(conn, wait = 1)
      wait ||= config.timeout if config.wait_for_lock?

      if wait.nil?
        rpoplpush(conn)
      else
        brpoplpush(conn, wait)
      end
    end

    #
    # @api private
    #
    def brpoplpush(conn, wait)
      # passing timeout 0 to brpoplpush causes it to block indefinitely
      raise InvalidArgument, "wait must be an integer" unless wait.is_a?(Integer)

      if defined?(::Redis::Namespace) && conn.instance_of?(::Redis::Namespace)
        return conn.brpoplpush(key.queued, key.primed, wait)
      end

      if VersionCheck.satisfied?(redis_version, ">= 6.2.0") && conn.respond_to?(:blmove)
        conn.blmove(key.queued, key.primed, "RIGHT", "LEFT", timeout: wait)
      else
        conn.brpoplpush(key.queued, key.primed, timeout: wait)
      end
    end

    #
    # @api private
    #
    def rpoplpush(conn)
      conn.rpoplpush(key.queued, key.primed)
    end

    #
    # Writes lock information to redis.
    #   The lock information contains information about worker, queue, limit etc.
    #
    #
    # @return [void]
    #
    def write_lock_info(conn)
      return unless config.lock_info?

      conn.set(key.info, lock_info)
    end

    #
    # Used to combat redis imprecision with ttl/pttl
    #
    # @param [Integer] val the value to compute drift for
    #
    # @return [Integer] a computed drift value
    #
    def drift(val)
      # Add 2 milliseconds to the drift to account for Redis expires
      # precision, which is 1 millisecond, plus 1 millisecond min drift
      # for small TTLs.
      (val + 2).to_f * CLOCK_DRIFT_FACTOR
    end

    def add_drift(val)
      val = val.to_f
      val + drift(val)
    end

    #
    # Checks if the lock has been taken
    #
    # @param [Redis] conn a redis connection
    #
    # @return [true, false]
    #
    def taken?(conn)
      conn.hexists(key.locked, job_id)
    end

    def argv
      [job_id, config.pttl, config.type, config.limit]
    end

    def lock_info
      @lock_info ||= dump_json(
        WORKER => item[CLASS],
        QUEUE => item[QUEUE],
        LIMIT => item[LOCK_LIMIT],
        TIMEOUT => item[LOCK_TIMEOUT],
        TTL => item[LOCK_TTL],
        TYPE => config.type,
        LOCK_ARGS => item[LOCK_ARGS],
        TIME => now_f,
      )
    end

    def redis_version
      @redis_version ||= SidekiqUniqueJobs.config.redis_version
    end
  end
end
