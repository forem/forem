# frozen_string_literal: true

class Redis
  class Cluster
    # Keep slot and node key map for Redis Cluster Client
    class Slot
      ROLE_SLAVE = 'slave'

      def initialize(available_slots, node_flags = {}, with_replica = false)
        @with_replica = with_replica
        @node_flags = node_flags
        @map = build_slot_node_key_map(available_slots)
      end

      def exists?(slot)
        @map.key?(slot)
      end

      def find_node_key_of_master(slot)
        return nil unless exists?(slot)

        @map[slot][:master]
      end

      def find_node_key_of_slave(slot)
        return nil unless exists?(slot)
        return find_node_key_of_master(slot) if replica_disabled?

        @map[slot][:slaves].sample
      end

      def put(slot, node_key)
        # Since we're sharing a hash for build_slot_node_key_map, duplicate it
        # if it already exists instead of preserving as-is.
        @map[slot] = @map[slot] ? @map[slot].dup : { master: nil, slaves: [] }

        if master?(node_key)
          @map[slot][:master] = node_key
        elsif !@map[slot][:slaves].include?(node_key)
          @map[slot][:slaves] << node_key
        end

        nil
      end

      private

      def replica_disabled?
        !@with_replica
      end

      def master?(node_key)
        !slave?(node_key)
      end

      def slave?(node_key)
        @node_flags[node_key] == ROLE_SLAVE
      end

      # available_slots is mapping of node_key to list of slot ranges
      def build_slot_node_key_map(available_slots)
        by_ranges = {}
        available_slots.each do |node_key, slots_arr|
          by_ranges[slots_arr] ||= { master: nil, slaves: [] }

          if master?(node_key)
            by_ranges[slots_arr][:master] = node_key
          elsif !by_ranges[slots_arr][:slaves].include?(node_key)
            by_ranges[slots_arr][:slaves] << node_key
          end
        end

        by_slot = {}
        by_ranges.each do |slots_arr, nodes|
          slots_arr.each do |slots|
            slots.each do |slot|
              by_slot[slot] = nodes
            end
          end
        end

        by_slot
      end
    end
  end
end
