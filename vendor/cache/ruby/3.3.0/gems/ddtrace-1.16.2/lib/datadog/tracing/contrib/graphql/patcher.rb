require_relative '../analytics'
require_relative '../patcher'

module Datadog
  module Tracing
    module Contrib
      module GraphQL
        # Provides instrumentation for `graphql` through the GraphQL tracing framework
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            if (schemas = get_option(:schemas))
              schemas.each { |s| patch_schema!(s) }
            end

            patch_legacy_gem!
          end

          def patch_schema!(schema)
            service_name = get_option(:service_name)
            analytics_enabled = Contrib::Analytics.enabled?(get_option(:analytics_enabled))
            analytics_sample_rate = get_option(:analytics_sample_rate)

            if schema.respond_to?(:use)
              schema.use(
                ::GraphQL::Tracing::DataDogTracing,
                # By default, Tracing::DataDogTracing holds a reference to a tracer.
                # If we provide a tracer argument here it will be eagerly cached,
                # and Tracing::DataDogTracing will send traces to a stale tracer instance.
                service: service_name,
                analytics_enabled: analytics_enabled,
                analytics_sample_rate: analytics_sample_rate
              )
            else
              schema.define do
                use(
                  ::GraphQL::Tracing::DataDogTracing,
                  # By default, Tracing::DataDogTracing holds a reference to a tracer.
                  # If we provide a tracer argument here it will be eagerly cached,
                  # and Tracing::DataDogTracing will send traces to a stale tracer instance.
                  service: service_name,
                  analytics_enabled: analytics_enabled,
                  analytics_sample_rate: analytics_sample_rate
                )
              end
            end
          end

          # Before https://github.com/rmosolgo/graphql-ruby/pull/4038 was introduced,
          # we were left with incompatibilities between ddtrace 1.0 and older graphql gem versions.
          def patch_legacy_gem!
            return unless Gem::Version.new(::GraphQL::VERSION) <= Gem::Version.new('2.0.6')

            ::GraphQL::Tracing::DataDogTracing.prepend(PatchLegacyGem)
          end

          def get_option(option)
            Datadog.configuration.tracing[:graphql].get_option(option)
          end

          # Patches the graphql gem to support ddtrace 1.0.
          # This is not necessary in versions containing https://github.com/rmosolgo/graphql-ruby/pull/4038.
          module PatchLegacyGem
            # Ensure invocation to #trace method targets the new namespaced public API object,
            # instead of the old global Datadog.trace.
            # This is fixed in graphql > 2.0.3.
            def tracer
              options.fetch(:tracer, Datadog::Tracing) # GraphQL will invoke #trace on the returned object
            end

            # Ensure resource name is not left as `nil`.
            # This is fixed in graphql > 2.0.6.
            def fallback_transaction_name(context)
              context[:tracing_fallback_transaction_name] || 'execute.graphql'
            end
          end
        end
      end
    end
  end
end
