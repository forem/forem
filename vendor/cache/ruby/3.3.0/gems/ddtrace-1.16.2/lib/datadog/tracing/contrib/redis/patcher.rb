require_relative '../patcher'
require_relative 'ext'
require_relative 'configuration/resolver'

module Datadog
  module Tracing
    module Contrib
      module Redis
        # Patcher enables patching of 'redis' module.
        module Patcher
          include Contrib::Patcher

          # Patch for redis instance
          module InstancePatch
            def self.included(base)
              base.prepend(InstanceMethods)
            end

            # Instance method patch for redis instance
            module InstanceMethods
              # `options` could be frozen
              def initialize(options = {})
                super(options.merge(redis_instance: self))
              end
            end
          end

          # Patch for redis client
          module ClientPatch
            def self.included(base)
              base.prepend(InstanceMethods)
            end

            # Instance method patch for redis client
            module InstanceMethods
              def initialize(options = {})
                @redis_instance = options.delete(:redis_instance)

                super(options)
              end

              private

              attr_reader :redis_instance
            end
          end

          module_function

          def default_tags
            [].tap do |tags|
              tags << "target_redis_version:#{Integration.redis_version}"               if Integration.redis_version
              tags << "target_redis_client_version:#{Integration.redis_client_version}" if Integration.redis_client_version
            end
          end

          def patch
            # Redis 5+ extracts RedisClient to its own gem and provide instrumentation interface
            if Integration.redis_client_compatible?
              require_relative 'trace_middleware'

              ::RedisClient.register(TraceMiddleware)
            end

            if Integration.redis_compatible? && Integration.redis_version < Gem::Version.new('5.0.0')
              require_relative 'instrumentation'

              ::Redis.include(InstancePatch)
              ::Redis::Client.include(ClientPatch)
              ::Redis::Client.include(Instrumentation)
            end
          end
        end
      end
    end
  end
end
