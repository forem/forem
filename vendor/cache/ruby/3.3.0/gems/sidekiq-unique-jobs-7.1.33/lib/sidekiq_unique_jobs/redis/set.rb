# frozen_string_literal: true

module SidekiqUniqueJobs
  module Redis
    #
    # Class Set provides convenient access to redis sets
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    class Set < Entity
      #
      # Return entries for this set
      #
      #
      # @return [Array<String>]
      #
      def entries
        redis { |conn| conn.smembers(key) }
      end

      #
      # Returns the count for this sorted set
      #
      #
      # @return [Integer] the number of entries
      #
      def count
        redis { |conn| conn.scard(key) }
      end
    end
  end
end
