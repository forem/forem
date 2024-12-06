# frozen_string_literal: true

require_relative '../../../encoding'
require_relative '../../../transport/http/api/map'

# TODO: Decouple standard transport/http/api/instance
#
# Separate classes are needed because transport/http/traces includes
# Trace::API::Instance which closes over and uses a single spec, which is
# negotiated as either /v3 or /v4 for the whole API at the spec level, but we
# need an independent toplevel path at the endpoint level.
#
# Separate classes are needed because of `include Trace::API::Instance`.
#
# Below should be:
# require_relative '../../../../ddtrace/transport/http/api/spec'
require_relative 'api/spec'

# TODO: only needed for Negotiation::API::Endpoint
require_relative 'negotiation'

# TODO: only needed for Config::API::Endpoint
require_relative 'config'

module Datadog
  module Core
    module Remote
      module Transport
        module HTTP
          # Namespace for API components
          module API
            # Default API versions
            ROOT = 'root'
            V7 = 'v0.7'

            module_function

            def defaults
              Datadog::Core::Transport::HTTP::API::Map[
                ROOT => Spec.new do |s|
                  s.info = Negotiation::API::Endpoint.new(
                    '/info',
                  )
                end,
                V7 => Spec.new do |s|
                  s.config = Config::API::Endpoint.new(
                    '/v0.7/config',
                    Core::Encoding::JSONEncoder,
                  )
                end,
              ]
            end
          end
        end
      end
    end
  end
end
