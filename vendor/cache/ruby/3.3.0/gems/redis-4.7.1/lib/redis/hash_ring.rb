# frozen_string_literal: true

require 'zlib'

class Redis
  class HashRing
    POINTS_PER_SERVER = 160 # this is the default in libmemcached

    attr_reader :ring, :sorted_keys, :replicas, :nodes

    # nodes is a list of objects that have a proper to_s representation.
    # replicas indicates how many virtual points should be used pr. node,
    # replicas are required to improve the distribution.
    def initialize(nodes = [], replicas = POINTS_PER_SERVER)
      @replicas = replicas
      @ring = {}
      @nodes = []
      @sorted_keys = []
      nodes.each do |node|
        add_node(node)
      end
    end

    # Adds a `node` to the hash ring (including a number of replicas).
    def add_node(node)
      @nodes << node
      @replicas.times do |i|
        key = Zlib.crc32("#{node.id}:#{i}")
        @ring[key] = node
        @sorted_keys << key
      end
      @sorted_keys.sort!
    end

    def remove_node(node)
      @nodes.reject! { |n| n.id == node.id }
      @replicas.times do |i|
        key = Zlib.crc32("#{node.id}:#{i}")
        @ring.delete(key)
        @sorted_keys.reject! { |k| k == key }
      end
    end

    # get the node in the hash ring for this key
    def get_node(key)
      get_node_pos(key)[0]
    end

    def get_node_pos(key)
      return [nil, nil] if @ring.empty?

      crc = Zlib.crc32(key)
      idx = HashRing.binary_search(@sorted_keys, crc)
      [@ring[@sorted_keys[idx]], idx]
    end

    def iter_nodes(key)
      return [nil, nil] if @ring.empty?

      _, pos = get_node_pos(key)
      @ring.size.times do |n|
        yield @ring[@sorted_keys[(pos + n) % @ring.size]]
      end
    end

    # Find the closest index in HashRing with value <= the given value
    def self.binary_search(ary, value)
      upper = ary.size - 1
      lower = 0
      idx = 0

      while lower <= upper
        idx = (lower + upper) / 2
        comp = ary[idx] <=> value

        if comp == 0
          return idx
        elsif comp > 0
          upper = idx - 1
        else
          lower = idx + 1
        end
      end

      upper = ary.size - 1 if upper < 0
      upper
    end
  end
end
