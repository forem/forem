class Redis
  class Store < self
    module Ttl
      def set(key, value, options = nil)
        if ttl = expires_in(options)
          setex(key, ttl.to_i, value, :raw => true)
        else
          super(key, value, options)
        end
      end

      def setnx(key, value, options = nil)
        if ttl = expires_in(options)
          setnx_with_expire(key, value, ttl.to_i, options)
        else
          super(key, value)
        end
      end

      protected
        def setnx_with_expire(key, value, ttl, options = {})
          with_multi_or_pipelined(options) do |transaction|
            if transaction.is_a?(Redis::Store) # for redis < 4.6
              setnx(key, value, :raw => true)
              expire(key, ttl)
            else
              transaction.setnx(key, value)
              transaction.expire(key, ttl)
            end
          end
        end

      private
        def expires_in(options)
          if options
            # Rack::Session           Merb                    Rails/Sinatra
            options[:expire_after] || options[:expires_in] || options[:expire_in]
          end
        end

        def with_multi_or_pipelined(options, &block)
          return pipelined(&block) if options.key?(:cluster) || options[:avoid_multi_commands]
          multi(&block)
        end
    end
  end
end
