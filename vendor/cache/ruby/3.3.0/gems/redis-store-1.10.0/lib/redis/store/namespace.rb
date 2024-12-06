class Redis
  class Store < self
    module Namespace
      FLUSHDB_BATCH_SIZE = 1000

      def set(key, *args)
        namespace(key) { |k| super(k, *args) }
      end

      def setex(key, *args)
        namespace(key) { |k| super(k, *args) }
      end

      def setnx(key, *args)
        namespace(key) { |k| super(k, *args) }
      end

      def ttl(key, options = nil)
        namespace(key) { |k| super(k) }
      end

      def get(key, *args)
        namespace(key) { |k| super(k, *args) }
      end

      def exists(*keys)
        super(*keys.map { |key| interpolate(key) })
      end

      def exists?(*keys)
        super(*keys.map { |key| interpolate(key) })
      end

      def incrby(key, increment)
        namespace(key) { |k| super(k, increment) }
      end

      def decrby(key, increment)
        namespace(key) { |k| super(k, increment) }
      end

      def keys(pattern = "*")
        namespace(pattern) { |p| super(p).map { |key| strip_namespace(key) } }
      end

      def scan(cursor, match: nil, **kwargs)
        if match
          namespace(match) do |pattern|
            cursor, keys = super(cursor, match: pattern, **kwargs)
            [ cursor, keys.map { |key| strip_namespace(key) } ]
          end
        else
          super(cursor, **kwargs)
        end
      end

      def del(*keys)
        super(*keys.map { |key| interpolate(key) }) if keys.any?
      end

      def unlink(*keys)
        super(*keys.map { |key| interpolate(key) }) if keys.any?
      end

      def watch(*keys)
        super(*keys.map { |key| interpolate(key) }) if keys.any?
      end

      def mget(*keys, &blk)
        options = (keys.pop if keys.last.is_a? Hash) || {}
        if keys.any?
          # Serialization gets extended before Namespace does, so we need to pass options further
          if singleton_class.ancestors.include? Serialization
            super(*keys.map { |key| interpolate(key) }, options, &blk)
          else
            super(*keys.map { |key| interpolate(key) }, &blk)
          end
        end
      end

      def expire(key, ttl)
        namespace(key) { |k| super(k, ttl) }
      end

      def hdel(key, *fields)
        namespace(key) { |k| super(k, *fields) }
      end

      def hget(key, field)
        namespace(key) { |k| super(k, field) }
      end

      def hgetall(key)
        namespace(key) { |k| super(k) }
      end

      def hexists(key, field)
        namespace(key) { |k| super(k, field) }
      end

      def hincrby(key, field, increment)
        namespace(key) { |k| super(k, field, increment) }
      end

      def hincrbyfloat(key, field, increment)
        namespace(key) { |k| super(k, field, increment) }
      end

      def hkeys(key)
        namespace(key) { |k| super(k) }
      end

      def hlen(key)
        namespace(key) { |k| super(k) }
      end

      def hmget(key, *fields, &blk)
        namespace(key) { |k| super(k, *fields, &blk) }
      end

      def hmset(key, *attrs)
        namespace(key) { |k| super(k, *attrs) }
      end

      def hset(key, *args)
        namespace(key) { |k| super(k, *args) }
      end

      def hsetnx(key, field, val)
        namespace(key) { |k| super(k, field, val) }
      end

      def hvals(key)
        namespace(key) { |k| super(k) }
      end

      def hscan(key, *args)
        namespace(key) { |k| super(k, *args) }
      end

      def hscan_each(key, *args)
        namespace(key) { |k| super(k, *args) }
      end

      def zincrby(key, increment, member)
        namespace(key) { |k| super(k, increment, member) }
      end

      def zscore(key, member)
        namespace(key) { |k| super(k, member) }
      end

      def zadd(key, *args)
        namespace(key) { |k| super(k, *args) }
      end

      def zrem(key, member)
        namespace(key) { |k| super(k, member) }
      end

      if respond_to?(:ruby2_keywords, true)
        ruby2_keywords :set, :setex, :setnx, :hscan, :hscan_each
      end

      def to_s
        if namespace_str
          "#{super} with namespace #{namespace_str}"
        else
          super
        end
      end

      def flushdb
        return super unless namespace_str
        keys.each_slice(FLUSHDB_BATCH_SIZE) { |key_slice| del(*key_slice) }
      end

      def with_namespace(ns)
        old_ns = @namespace
        @namespace = ns
        yield self
      ensure
        @namespace = old_ns
      end

      private
        def namespace(key)
          yield interpolate(key)
        end

        def namespace_str
          @namespace.is_a?(Proc) ? @namespace.call : @namespace
        end

        def interpolate(key)
          return key unless namespace_str
          key.match(namespace_regexp) ? key : "#{namespace_str}:#{key}"
        end

        def strip_namespace(key)
          return key unless namespace_str
          key.gsub namespace_regexp, ""
        end

        def namespace_regexp
          @namespace_regexps ||= {}
          @namespace_regexps[namespace_str] ||= %r{^#{namespace_str}\:}
        end
    end
  end
end
