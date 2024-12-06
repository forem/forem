# frozen_string_literal: true

module Datadog
  module Tracing
    module Transport
      module HTTP
        module API
          # An API configured with adapter and routes
          class Instance
            attr_reader \
              :adapter,
              :headers,
              :spec

            def initialize(spec, adapter, options = {})
              @spec = spec
              @adapter = adapter
              @headers = options.fetch(:headers, {})
            end

            def encoder
              spec.encoder
            end

            def call(env)
              # Add headers to request env, unless empty.
              env.headers.merge!(headers) unless headers.empty?

              # Send request env to the adapter.
              adapter.call(env)
            end
          end
        end
      end
    end
  end
end
