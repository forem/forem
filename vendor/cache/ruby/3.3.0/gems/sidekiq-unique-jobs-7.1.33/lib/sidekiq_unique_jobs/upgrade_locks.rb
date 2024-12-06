# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Upgrades locks between gem version upgrades
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class UpgradeLocks # rubocop:disable Metrics/ClassLength
    #
    # @return [Integer] the number of keys to batch upgrade
    BATCH_SIZE = 100
    #
    # @return [Array<String>] suffixes for old version
    OLD_SUFFIXES = %w[
      GRABBED
      AVAILABLE
      EXISTS
      VERSION
    ].freeze

    include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::Connection

    #
    # Performs upgrade of old locks
    #
    #
    # @return [Integer] the number of upgrades locks
    #
    def self.call
      redis do |conn|
        new(conn).call
      end
    end

    attr_reader :conn

    def initialize(conn)
      @count         = 0
      @conn          = conn
      redis_version # Avoid pipelined calling redis_version and getting a future.
    end

    #
    # Performs upgrade of old locks
    #
    #
    # @return [Integer] the number of upgrades locks
    #
    def call
      with_logging_context do
        return log_info("Already upgraded to #{version}") if conn.hget(upgraded_key, version)
        # TODO: Needs handling of v7.0.0 => v7.0.1 where we don't want to
        return log_info("Skipping upgrade because #{DEAD_VERSION} has been set") if conn.get(DEAD_VERSION)

        log_info("Start - Upgrading Locks")

        upgrade_v6_locks
        delete_unused_v6_keys
        delete_supporting_v6_keys

        conn.hset(upgraded_key, version, now_f)
        log_info("Done - Upgrading Locks")
      end

      @count
    end

    private

    def upgraded_key
      @upgraded_key ||= "#{LIVE_VERSION}:UPGRADED"
    end

    def upgrade_v6_locks
      log_info("Start - Converting v6 locks to v7")
      conn.scan_each(match: "*:GRABBED", count: BATCH_SIZE) do |grabbed_key|
        upgrade_v6_lock(grabbed_key)
        @count += 1
      end
      log_info("Done - Converting v6 locks to v7")
    end

    def upgrade_v6_lock(grabbed_key)
      locked_key = grabbed_key.gsub(":GRABBED", ":LOCKED")
      digest     = grabbed_key.gsub(":GRABBED", "")
      locks      = conn.hgetall(grabbed_key)

      conn.pipelined do |pipeline|
        pipeline.hmset(locked_key, *locks.to_a)
        pipeline.zadd(DIGESTS, locks.values.first, digest)
      end
    end

    def delete_unused_v6_keys
      log_info("Start - Deleting v6 keys")
      OLD_SUFFIXES.each do |suffix|
        delete_suffix(suffix)
      end
      log_info("Done - Deleting v6 keys")
    end

    def delete_supporting_v6_keys
      batch_delete("unique:keys")
    end

    def delete_suffix(suffix)
      batch_scan(match: "*:#{suffix}", count: BATCH_SIZE) do |keys|
        batch_delete(*keys)
      end
    end

    def batch_delete(*keys)
      return if keys.empty?

      conn.pipelined do |pipeline|
        if VersionCheck.satisfied?(redis_version, ">= 4.0.0")
          pipeline.unlink(*keys)
        else
          pipeline.del(*keys)
        end
      end
    end

    def batch_scan(match:, count:)
      cursor = "0"
      loop do
        cursor, values = conn.scan(cursor, match: match, count: count)
        yield values
        break if cursor == "0"
      end
    end

    def version
      SidekiqUniqueJobs.version
    end

    def now_f
      SidekiqUniqueJobs.now_f
    end

    def redis_version
      @redis_version ||= SidekiqUniqueJobs.config.redis_version
    end

    def logging_context
      if logger_context_hash?
        { "uniquejobs" => :upgrade_locks }
      else
        "uniquejobs-upgrade_locks"
      end
    end
  end
end
