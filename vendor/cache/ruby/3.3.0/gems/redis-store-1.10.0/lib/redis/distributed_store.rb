require 'redis/distributed'

class Redis
  class DistributedStore < Distributed
    @@timeout = 5
    attr_reader :ring

    def initialize(addresses, options = {})
      _extend_namespace options
      # `@tag` introduced in `redis-rb` 5.0
      @tag = options[:tag] || /^\{(.+?)\}/
      @ring = options[:ring] || Redis::HashRing.new([], options[:replicas] || Redis::HashRing::POINTS_PER_SERVER)

      addresses.each do |address|
        @ring.add_node(::Redis::Store.new _merge_options(address, options))
      end
    end

    def nodes
      ring.nodes
    end

    def reconnect
      nodes.each { |node| node.reconnect }
    end

    def set(key, value, options = nil)
      node_for(key).set(key, value, options)
    end

    def get(key, options = nil)
      node_for(key).get(key, options)
    end

    def setnx(key, value, options = nil)
      node_for(key).setnx(key, value, options)
    end

    def redis_version
      nodes.first.redis_version unless nodes.empty?
    end

    def supports_redis_version?(version)
      if nodes.empty?
        false
      else
        nodes.first.supports_redis_version?(version)
      end
    end

    def setex(key, expiry, value, options = nil)
      node_for(key).setex(key, expiry, value, options)
    end

    private
      def _extend_namespace(options)
        @namespace = options[:namespace]
        extend ::Redis::Store::Namespace if @namespace
      end

      def _merge_options(address, options)
        address.merge(
          :timeout => options[:timeout] || @@timeout,
          :namespace => options[:namespace]
        )
      end
  end
end
