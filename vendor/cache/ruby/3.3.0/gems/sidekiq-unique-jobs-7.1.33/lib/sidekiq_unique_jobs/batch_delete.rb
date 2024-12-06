# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Class BatchDelete provides batch deletion of digests
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class BatchDelete
    #
    # @return [Integer] the default batch size
    BATCH_SIZE = 100

    #
    # @return [Array<String>] Supported key suffixes
    SUFFIXES = %w[
      QUEUED
      PRIMED
      LOCKED
      INFO
    ].freeze

    # includes "SidekiqUniqueJobs::Connection"
    # @!parse include SidekiqUniqueJobs::Connection
    include SidekiqUniqueJobs::Connection
    # includes "SidekiqUniqueJobs::Logging"
    # @!parse include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::Logging

    #
    # @!attribute [r] digests
    #   @return [Array<String>] a collection of digests to be deleted
    attr_reader :digests
    #
    # @!attribute [r] conn
    #   @return [Redis, RedisConnection, ConnectionPool] a redis connection
    attr_reader :conn

    #
    # Executes a batch deletion of the provided digests
    #
    # @param [Array<String>] digests the digests to delete
    # @param [Redis] conn the connection to use for deletion
    #
    # @return [void]
    #
    def self.call(digests, conn = nil)
      new(digests, conn).call
    end

    #
    # Initialize a new batch delete instance
    #
    # @param [Array<String>] digests the digests to delete
    # @param [Redis] conn the connection to use for deletion
    #
    def initialize(digests, conn)
      @count   = 0
      @digests = digests
      @conn    = conn
      @digests ||= []
      @digests.compact!
      redis_version # Avoid pipelined calling redis_version and getting a future.
    end

    #
    # Executes a batch deletion of the provided digests
    # @note Just wraps batch_delete to be able to provide no connection
    #
    #
    def call
      return log_info("Nothing to delete; exiting.") if digests.none?

      log_info("Deleting batch with #{digests.size} digests")
      return batch_delete(conn) if conn

      redis { |rcon| batch_delete(rcon) }
    end

    private

    #
    # Does the actual batch deletion
    #
    #
    # @return [Integer] the number of deleted digests
    #
    def batch_delete(conn)
      digests.each_slice(BATCH_SIZE) do |chunk|
        conn.pipelined do |pipeline|
          chunk.each do |digest|
            del_digest(pipeline, digest)
            pipeline.zrem(SidekiqUniqueJobs::DIGESTS, digest)
            pipeline.zrem(SidekiqUniqueJobs::EXPIRING_DIGESTS, digest)
            @count += 1
          end
        end
      end

      @count
    end

    def del_digest(pipeline, digest)
      removable_keys = keys_for_digest(digest)

      if VersionCheck.satisfied?(redis_version, ">= 4.0.0")
        pipeline.unlink(*removable_keys)
      else
        pipeline.del(*removable_keys)
      end
    end

    def keys_for_digest(digest)
      [digest, "#{digest}:RUN"].each_with_object([]) do |key, digest_keys|
        digest_keys.push(key)
        digest_keys.concat(SUFFIXES.map { |suffix| "#{key}:#{suffix}" })
      end
    end

    def redis_version
      @redis_version ||= SidekiqUniqueJobs.config.redis_version
    end
  end
end
