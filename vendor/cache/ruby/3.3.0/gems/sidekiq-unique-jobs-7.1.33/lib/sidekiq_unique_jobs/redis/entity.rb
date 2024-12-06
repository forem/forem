# frozen_string_literal: true

module SidekiqUniqueJobs
  module Redis
    #
    # Class Entity functions as a base class for redis types
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    class Entity
      # includes "SidekiqUniqueJobs::Logging"
      # @!parse include SidekiqUniqueJobs::Logging
      include SidekiqUniqueJobs::Logging

      # includes "SidekiqUniqueJobs::Script::Caller"
      # @!parse include SidekiqUniqueJobs::Script::Caller
      include SidekiqUniqueJobs::Script::Caller

      # includes "SidekiqUniqueJobs::JSON"
      # @!parse include SidekiqUniqueJobs::JSON
      include SidekiqUniqueJobs::JSON

      # includes "SidekiqUniqueJobs::Timing"
      # @!parse include SidekiqUniqueJobs::Timing
      include SidekiqUniqueJobs::Timing

      #
      # @!attribute [r] key
      #   @return [String] the redis key for this entity
      attr_reader :key

      #
      # Initialize a new Entity
      #
      # @param [String] key the redis key for this entity
      #
      def initialize(key)
        @key = key
      end

      #
      # Checks if the key for this entity exists in redis
      #
      #
      # @return [true] when exists
      # @return [false] when not exists
      #
      def exist?
        redis do |conn|
          # TODO: Remove the if statement in the future
          value =
            if conn.respond_to?(:exists?)
              conn.exists?(key)
            else
              conn.exists(key)
            end

          return value if boolean?(value)

          value.to_i.positive?
        end
      end

      #
      # The number of microseconds until the key expires
      #
      #
      # @return [Integer] expiration in milliseconds
      #
      def pttl
        redis { |conn| conn.pttl(key) }
      end

      #
      # The number of seconds until the key expires
      #
      #
      # @return [Integer] expiration in seconds
      #
      def ttl
        redis { |conn| conn.ttl(key) }
      end

      #
      # Check if the entity has expiration
      #
      #
      # @return [true] when entity is set to exire
      # @return [false] when entity isn't expiring
      #
      def expires?
        pttl.positive? || ttl.positive?
      end

      #
      # Returns the number of entries in this entity
      #
      #
      # @return [Integer] 0
      #
      def count
        0
      end

      private

      def boolean?(value)
        [TrueClass, FalseClass].any? { |klazz| value.is_a?(klazz) }
      end
    end
  end
end
