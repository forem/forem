# frozen_string_literal: true

require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module ActiveSupport
        module Cache
          # Support for Redis with ActiveSupport
          module Redis
            # Patching behavior for Redis with ActiveSupport
            module Patcher
              # For Rails < 5.2 w/ redis-activesupport...
              # When Redis is used, we can't only patch Cache::Store as it is
              # Cache::RedisStore, a sub-class of it that is used, in practice.
              # We need to do a per-method monkey patching as some of them might
              # be redefined, and some of them not. The latest version of redis-activesupport
              # redefines write but leaves untouched read and delete:
              # https://github.com/redis-store/redis-activesupport/blob/v4.1.5/lib/active_support/cache/redis_store.rb
              #
              # For Rails >= 5.2 w/o redis-activesupport...
              # ActiveSupport includes a Redis cache store internally, and does not require these overrides.
              # https://github.com/rails/rails/blob/master/activesupport/lib/active_support/cache/redis_cache_store.rb
              def patch_redis?(meth)
                !Gem.loaded_specs['redis-activesupport'].nil? \
                  && defined?(::ActiveSupport::Cache::RedisStore) \
                  && ::ActiveSupport::Cache::RedisStore.instance_methods(false).include?(meth)
              end

              def cache_store_class(meth)
                if patch_redis?(meth)
                  ::ActiveSupport::Cache::RedisStore
                else
                  super
                end
              end
            end

            # Decorate Cache patcher with Redis support
            Cache::Patcher.singleton_class.prepend(Redis::Patcher)
          end
        end
      end
    end
  end
end
