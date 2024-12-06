# frozen_string_literal: true

module SidekiqUniqueJobs
  module Orphans
    #
    # Class DeleteOrphans provides deletion of orphaned digests
    #
    # @note this is a much slower version of the lua script but does not crash redis
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    class Reaper
      include SidekiqUniqueJobs::Connection
      include SidekiqUniqueJobs::Script::Caller
      include SidekiqUniqueJobs::Logging
      include SidekiqUniqueJobs::JSON

      require_relative "lua_reaper"
      require_relative "ruby_reaper"
      require_relative "null_reaper"

      #
      # @return [Hash<Symbol, SidekiqUniqueJobs::Orphans::Reaper] the current implementation of reapers
      REAPERS = {
        lua: SidekiqUniqueJobs::Orphans::LuaReaper,
        ruby: SidekiqUniqueJobs::Orphans::RubyReaper,
        none: SidekiqUniqueJobs::Orphans::NullReaper,
        nil => SidekiqUniqueJobs::Orphans::NullReaper,
        false => SidekiqUniqueJobs::Orphans::NullReaper,
      }.freeze

      #
      # Execute deletion of orphaned digests
      #
      # @param [Redis] conn nil a connection to redis
      #
      # @return [void]
      #
      def self.call(conn = nil)
        return new(conn).call if conn

        redis { |rcon| new(rcon).call }
      end

      #
      # @!attribute [r] conn
      #   @return [Redis] a redis connection
      attr_reader :conn

      #
      # Initialize a new instance of DeleteOrphans
      #
      # @param [Redis] conn a connection to redis
      #
      def initialize(conn)
        @conn = conn
      end

      #
      # Convenient access to the global configuration
      #
      #
      # @return [SidekiqUniqueJobs::Config]
      #
      def config
        SidekiqUniqueJobs.config
      end

      #
      # The reaper that was configured
      #
      #
      # @return [Symbol]
      #
      def reaper
        config.reaper
      end

      #
      # The configured timeout for the reaper
      #
      #
      # @return [Integer] timeout in seconds
      #
      def reaper_timeout
        config.reaper_timeout
      end

      #
      # The number of locks to reap at a time
      #
      #
      # @return [Integer]
      #
      def reaper_count
        config.reaper_count
      end

      #
      # Delete orphaned digests
      #
      #
      # @return [Integer] the number of reaped locks
      #
      def call
        if (implementation = REAPERS[reaper])
          implementation.new(conn).call
        else
          log_fatal(":#{reaper} is invalid for `SidekiqUnqiueJobs.config.reaper`")
        end
      end
    end
  end
end
