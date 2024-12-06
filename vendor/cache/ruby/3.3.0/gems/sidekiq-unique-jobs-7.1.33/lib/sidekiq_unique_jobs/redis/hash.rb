# frozen_string_literal: true

module SidekiqUniqueJobs
  module Redis
    #
    # Class Hash provides convenient access to redis hashes
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    class Hash < Entity
      #
      # Return entries for this hash
      #
      # @param [true,false] with_values false return hash
      #
      # @return [Array<Object>] when given with_values: false
      # @return [Hash<String, String>] when given with_values: true
      #
      def entries(with_values: false)
        if with_values
          redis { |conn| conn.hgetall(key) }
        else
          redis { |conn| conn.hkeys(key) }
        end
      end

      #
      # Removes the key from redis
      #
      def del(*fields)
        redis { |conn| conn.hdel(key, *fields) }
      end

      #
      # Get a members value
      #
      # @param [String] member the member who's value to get
      #
      # @return [Object] whatever is stored on this hash member
      #
      def [](member)
        redis { |conn| conn.hget(key, member) }
      end

      #
      # Returns the count for this hash
      #
      #
      # @return [Integer] the length of this hash
      #
      def count
        redis { |conn| conn.hlen(key) }
      end
    end
  end
end
