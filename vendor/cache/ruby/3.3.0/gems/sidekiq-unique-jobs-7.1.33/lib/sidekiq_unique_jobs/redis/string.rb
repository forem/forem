# frozen_string_literal: true

module SidekiqUniqueJobs
  module Redis
    #
    # Class String provides convenient access to redis strings
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    class String < Entity
      #
      # Returns the value of the key
      #
      #
      # @return [String]
      #
      def value
        redis { |conn| conn.get(key) }
      end

      #
      # Sets the value of the key to given object
      #
      # @param [String] obj the object to update the key with
      #
      # @return [true, false]
      #
      def set(obj, pipeline = nil)
        return pipeline.set(key, obj) if pipeline

        redis { |conn| conn.set(key, obj) }
      end

      #
      # Removes the key from redis
      #
      def del(*)
        redis { |conn| conn.del(key) }
      end

      #
      # Used only for compatibility with other keys
      #
      # @return [1] when key exists
      # @return [0] when key does not exists
      def count
        exist? ? 1 : 0
      end
    end
  end
end
