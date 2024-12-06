# frozen_string_literal: true

class Redis
  module Commands
    module Sets
      # Get the number of members in a set.
      #
      # @param [String] key
      # @return [Integer]
      def scard(key)
        send_command([:scard, key])
      end

      # Add one or more members to a set.
      #
      # @param [String] key
      # @param [String, Array<String>] member one member, or array of members
      # @return [Boolean, Integer] `Boolean` when a single member is specified,
      #   holding whether or not adding the member succeeded, or `Integer` when an
      #   array of members is specified, holding the number of members that were
      #   successfully added
      def sadd(key, member)
        send_command([:sadd, key, member]) do |reply|
          if member.is_a? Array
            # Variadic: return integer
            reply
          else
            # Single argument: return boolean
            Boolify.call(reply)
          end
        end
      end

      # Remove one or more members from a set.
      #
      # @param [String] key
      # @param [String, Array<String>] member one member, or array of members
      # @return [Boolean, Integer] `Boolean` when a single member is specified,
      #   holding whether or not removing the member succeeded, or `Integer` when an
      #   array of members is specified, holding the number of members that were
      #   successfully removed
      def srem(key, member)
        send_command([:srem, key, member]) do |reply|
          if member.is_a? Array
            # Variadic: return integer
            reply
          else
            # Single argument: return boolean
            Boolify.call(reply)
          end
        end
      end

      # Remove and return one or more random member from a set.
      #
      # @param [String] key
      # @return [String]
      # @param [Integer] count
      def spop(key, count = nil)
        if count.nil?
          send_command([:spop, key])
        else
          send_command([:spop, key, count])
        end
      end

      # Get one or more random members from a set.
      #
      # @param [String] key
      # @param [Integer] count
      # @return [String]
      def srandmember(key, count = nil)
        if count.nil?
          send_command([:srandmember, key])
        else
          send_command([:srandmember, key, count])
        end
      end

      # Move a member from one set to another.
      #
      # @param [String] source source key
      # @param [String] destination destination key
      # @param [String] member member to move from `source` to `destination`
      # @return [Boolean]
      def smove(source, destination, member)
        send_command([:smove, source, destination, member], &Boolify)
      end

      # Determine if a given value is a member of a set.
      #
      # @param [String] key
      # @param [String] member
      # @return [Boolean]
      def sismember(key, member)
        send_command([:sismember, key, member], &Boolify)
      end

      # Determine if multiple values are members of a set.
      #
      # @param [String] key
      # @param [String, Array<String>] members
      # @return [Array<Boolean>]
      def smismember(key, *members)
        send_command([:smismember, key, *members]) do |reply|
          reply.map(&Boolify)
        end
      end

      # Get all the members in a set.
      #
      # @param [String] key
      # @return [Array<String>]
      def smembers(key)
        send_command([:smembers, key])
      end

      # Subtract multiple sets.
      #
      # @param [String, Array<String>] keys keys pointing to sets to subtract
      # @return [Array<String>] members in the difference
      def sdiff(*keys)
        send_command([:sdiff, *keys])
      end

      # Subtract multiple sets and store the resulting set in a key.
      #
      # @param [String] destination destination key
      # @param [String, Array<String>] keys keys pointing to sets to subtract
      # @return [Integer] number of elements in the resulting set
      def sdiffstore(destination, *keys)
        send_command([:sdiffstore, destination, *keys])
      end

      # Intersect multiple sets.
      #
      # @param [String, Array<String>] keys keys pointing to sets to intersect
      # @return [Array<String>] members in the intersection
      def sinter(*keys)
        send_command([:sinter, *keys])
      end

      # Intersect multiple sets and store the resulting set in a key.
      #
      # @param [String] destination destination key
      # @param [String, Array<String>] keys keys pointing to sets to intersect
      # @return [Integer] number of elements in the resulting set
      def sinterstore(destination, *keys)
        send_command([:sinterstore, destination, *keys])
      end

      # Add multiple sets.
      #
      # @param [String, Array<String>] keys keys pointing to sets to unify
      # @return [Array<String>] members in the union
      def sunion(*keys)
        send_command([:sunion, *keys])
      end

      # Add multiple sets and store the resulting set in a key.
      #
      # @param [String] destination destination key
      # @param [String, Array<String>] keys keys pointing to sets to unify
      # @return [Integer] number of elements in the resulting set
      def sunionstore(destination, *keys)
        send_command([:sunionstore, destination, *keys])
      end

      # Scan a set
      #
      # @example Retrieve the first batch of keys in a set
      #   redis.sscan("set", 0)
      #
      # @param [String, Integer] cursor the cursor of the iteration
      # @param [Hash] options
      #   - `:match => String`: only return keys matching the pattern
      #   - `:count => Integer`: return count keys at most per iteration
      #
      # @return [String, Array<String>] the next cursor and all found members
      def sscan(key, cursor, **options)
        _scan(:sscan, cursor, [key], **options)
      end

      # Scan a set
      #
      # @example Retrieve all of the keys in a set
      #   redis.sscan_each("set").to_a
      #   # => ["key1", "key2", "key3"]
      #
      # @param [Hash] options
      #   - `:match => String`: only return keys matching the pattern
      #   - `:count => Integer`: return count keys at most per iteration
      #
      # @return [Enumerator] an enumerator for all keys in the set
      def sscan_each(key, **options, &block)
        return to_enum(:sscan_each, key, **options) unless block_given?

        cursor = 0
        loop do
          cursor, keys = sscan(key, cursor, **options)
          keys.each(&block)
          break if cursor == "0"
        end
      end
    end
  end
end
