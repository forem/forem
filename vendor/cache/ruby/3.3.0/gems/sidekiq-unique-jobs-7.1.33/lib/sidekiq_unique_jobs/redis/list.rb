# frozen_string_literal: true

module SidekiqUniqueJobs
  module Redis
    #
    # Class List provides convenient access to redis hashes
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    class List < Entity
      #
      # Entries in this list
      #
      #
      # @return [Array<Object>] the elements in this list
      #
      def entries
        redis { |conn| conn.lrange(key, 0, -1) }
      end

      #
      # The number of entries in this list
      #
      #
      # @return [Integer] the total number of entries
      #
      def count
        redis { |conn| conn.llen(key) }
      end
    end
  end
end
