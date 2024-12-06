# frozen_string_literal: true

module SidekiqUniqueJobs
  module OnConflict
    # Abstract conflict strategy class
    #
    # @abstract
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class Strategy
      include SidekiqUniqueJobs::JSON
      include SidekiqUniqueJobs::Logging
      include SidekiqUniqueJobs::Script::Caller
      include SidekiqUniqueJobs::Timing

      # @!attribute [r] item
      #   @return [Hash] sidekiq job hash
      attr_reader :item
      # @!attribute [r] redis_pool
      #   @return [Sidekiq::RedisConnection, ConnectionPool, NilClass] the redis connection
      attr_reader :redis_pool

      #
      # Initialize a new Strategy
      #
      # @param [Hash] item sidekiq job hash
      # @param [ConnectionPool] redis_pool the connection pool instance
      #
      def initialize(item, redis_pool = nil)
        @item       = item
        @redis_pool = redis_pool
      end

      # Use strategy on conflict
      # @raise [NotImplementedError] needs to be implemented in child class
      def call
        raise NotImplementedError, "needs to be implemented in child class"
      end

      #
      # Check if the strategy is kind of {Replace}
      #
      #
      # @return [true] when the strategy is a {Replace}
      # @return [false] when the strategy is not a {Replace}
      #
      def replace?
        is_a?(Replace)
      end
    end
  end
end
