# frozen_string_literal: true

require_relative '../../../../core/utils'
require_relative '../../../metadata/ext'
require_relative '../ext'

module Datadog
  module Tracing
    module Contrib
      module ActiveSupport
        module Cache
          # Defines instrumentation for ActiveSupport caching
          module Instrumentation
            module_function

            # @param action [String] type of cache operation. Will be set as the span resource.
            # @param key [Object] redis cache key. Used for actions with a single key locator.
            # @param multi_key [Array<Object>] list of redis cache keys. Used for actions with a multiple key locators.
            def trace(action, store, key: nil, multi_key: nil)
              return yield unless enabled?

              # create a new ``Span`` and add it to the tracing context
              Tracing.trace(
                Ext::SPAN_CACHE,
                span_type: Ext::SPAN_TYPE_CACHE,
                service: Datadog.configuration.tracing[:active_support][:cache_service],
                resource: action
              ) do |span|
                span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
                span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_CACHE)

                if span.service != Datadog.configuration.service
                  span.set_tag(Tracing::Contrib::Ext::Metadata::TAG_BASE_SERVICE, Datadog.configuration.service)
                end

                span.set_tag(Ext::TAG_CACHE_BACKEND, store) if store
                set_cache_key(span, key, multi_key)

                yield
              end
            end

            # In most of the cases, `#fetch()` and `#read()` calls are nested.
            # Instrument both does not add any value.
            # This method checks if these two operations are nested.
            def nested_read?
              current_span = Tracing.active_span
              current_span && current_span.name == Ext::SPAN_CACHE && current_span.resource == Ext::RESOURCE_CACHE_GET
            end

            # (see #nested_read?)
            def nested_multiread?
              current_span = Tracing.active_span
              current_span && current_span.name == Ext::SPAN_CACHE && current_span.resource == Ext::RESOURCE_CACHE_MGET
            end

            def set_cache_key(span, single_key, multi_key)
              if multi_key
                resolved_key = multi_key.map { |key| ::ActiveSupport::Cache.expand_cache_key(key) }
                cache_key = Core::Utils.truncate(resolved_key, Ext::QUANTIZE_CACHE_MAX_KEY_SIZE)
                span.set_tag(Ext::TAG_CACHE_KEY_MULTI, cache_key)
              else
                resolved_key = ::ActiveSupport::Cache.expand_cache_key(single_key)
                cache_key = Core::Utils.truncate(resolved_key, Ext::QUANTIZE_CACHE_MAX_KEY_SIZE)
                span.set_tag(Ext::TAG_CACHE_KEY, cache_key)
              end
            end

            def enabled?
              Tracing.enabled? && Datadog.configuration.tracing[:active_support][:enabled]
            end

            # Instance methods injected into the cache client
            module InstanceMethods
              private

              # The name of the store is never saved.
              # ActiveSupport looks up stores by converting a symbol into a 'require' path,
              # then "camelizing" it for a `const_get` call:
              # ```
              # require "active_support/cache/#{store}"
              # ActiveSupport::Cache.const_get(store.to_s.camelize)
              # ```
              # @see https://github.com/rails/rails/blob/261975dbef77731d2c76f907f1076c5132ebc0e4/activesupport/lib/active_support/cache.rb#L139-L149
              #
              # As `self` is the store object, we can reverse engineer
              # the original symbol by converting the class name to snake case:
              # e.g. ActiveSupport::Cache::RedisStore -> active_support/cache/redis_store
              # In this case, `redis_store` is the store name.
              #
              # Because there's no API retrieve only the class name
              # (only `RedisStore`, and not `ActiveSupport::Cache::RedisStore`)
              # the easiest way to retrieve the store symbol is to convert the fully qualified
              # name using the Rails-provided method `#underscore`, which is the reverse of `#camelize`,
              # then extracting the last part of it.
              #
              # Also, this method caches the store name, given this value will be retrieve
              # multiple times and involves string manipulation.
              def dd_store_name
                return @store_name if defined?(@store_name)

                # DEV: String#underscore is available through ActiveSupport, and is
                # DEV: the exact reverse operation to `#camelize`.
                # DEV: String#demodulize is available through ActiveSupport, and is
                # DEV: used to remove the module ('*::') part of a constant name.
                @store_name = self.class.name.demodulize.underscore
              end
            end

            # Defines instrumentation for ActiveSupport cache reading
            module Read
              include InstanceMethods

              def read(*args, &block)
                return super if Instrumentation.nested_read?

                Instrumentation.trace(Ext::RESOURCE_CACHE_GET, dd_store_name, key: args[0]) { super }
              end
            end

            # Defines instrumentation for ActiveSupport cache reading of multiple keys
            module ReadMulti
              include InstanceMethods

              def read_multi(*keys, &block)
                return super if Instrumentation.nested_multiread?

                Instrumentation.trace(Ext::RESOURCE_CACHE_MGET, dd_store_name, multi_key: keys) { super }
              end
            end

            # Defines instrumentation for ActiveSupport cache fetching
            module Fetch
              include InstanceMethods

              def fetch(*args, &block)
                return super if Instrumentation.nested_read?

                Instrumentation.trace(Ext::RESOURCE_CACHE_GET, dd_store_name, key: args[0]) { super }
              end
            end

            # Defines instrumentation for ActiveSupport cache fetching of multiple keys
            module FetchMulti
              include InstanceMethods

              def fetch_multi(*args, &block)
                return super if Instrumentation.nested_multiread?

                keys = args[-1].instance_of?(Hash) ? args[0..-2] : args
                Instrumentation.trace(Ext::RESOURCE_CACHE_MGET, dd_store_name, multi_key: keys) { super }
              end
            end

            # Defines instrumentation for ActiveSupport cache writing
            module Write
              include InstanceMethods

              def write(*args, &block)
                Instrumentation.trace(Ext::RESOURCE_CACHE_SET, dd_store_name, key: args[0]) { super }
              end
            end

            # Defines instrumentation for ActiveSupport cache writing of multiple keys
            module WriteMulti
              include InstanceMethods

              def write_multi(hash, options = nil)
                Instrumentation.trace(Ext::RESOURCE_CACHE_MSET, dd_store_name, multi_key: hash.keys) { super }
              end
            end

            # Defines instrumentation for ActiveSupport cache deleting
            module Delete
              include InstanceMethods

              def delete(*args, &block)
                Instrumentation.trace(Ext::RESOURCE_CACHE_DELETE, dd_store_name, key: args[0]) { super }
              end
            end
          end
        end
      end
    end
  end
end
