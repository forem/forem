# frozen_string_literal: true

require_relative '../../patcher'
require_relative 'instrumentation'

module Datadog
  module Tracing
    module Contrib
      module ActiveSupport
        module Cache
          # Patcher enables patching of 'active_support' module.
          module Patcher
            include Contrib::Patcher

            module_function

            def target_version
              Integration.version
            end

            def patch
              patch_cache_store_read
              patch_cache_store_read_multi
              patch_cache_store_fetch
              patch_cache_store_fetch_multi
              patch_cache_store_write
              patch_cache_store_write_multi
              patch_cache_store_delete
            end

            # This method is overwritten by
            # `datadog/tracing/contrib/active_support/cache/redis.rb`
            # with more complex behavior.
            def cache_store_class(meth)
              ::ActiveSupport::Cache::Store
            end

            def patch_cache_store_read
              cache_store_class(:read).prepend(Cache::Instrumentation::Read)
            end

            def patch_cache_store_read_multi
              cache_store_class(:read_multi).prepend(Cache::Instrumentation::ReadMulti)
            end

            def patch_cache_store_fetch
              cache_store_class(:fetch).prepend(Cache::Instrumentation::Fetch)
            end

            def patch_cache_store_fetch_multi
              klass = cache_store_class(:fetch_multi)
              return unless klass.public_method_defined?(:fetch_multi)

              klass.prepend(Cache::Instrumentation::FetchMulti)
            end

            def patch_cache_store_write
              cache_store_class(:write).prepend(Cache::Instrumentation::Write)
            end

            def patch_cache_store_write_multi
              klass = cache_store_class(:write_multi)
              return unless klass.public_method_defined?(:write_multi)

              klass.prepend(Cache::Instrumentation::WriteMulti)
            end

            def patch_cache_store_delete
              cache_store_class(:delete).prepend(Cache::Instrumentation::Delete)
            end
          end
        end
      end
    end
  end
end
