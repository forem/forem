# frozen_string_literal: true

require_relative '../../../core/transport/request'

# TODO: Resolve conceptual conundrum
#
# It seems that through naming of `Transport::Traces::Transport` the transport
# is specific to traces, which kind of matches the almost-generic-but-not-quite
# implementation.
#
# This may be why `Transport::Traces::Transport` negotiates only considering
# the `/vX/traces` path, but here we don't negotiate since we are at the root.
#
# In turn this means that API::Spec cannot describe multiple roots, or even
# endpoints that happen to differ in version.
#
# Concepts such as Spec, API, Endpoint, and Transport should be clarified
# before attempting further refactoring here, to attempt to resolve whether a
# Transport - via its negotiated Spec - describes a function (implemented as
# one or more endpoints) or whether the Spec describes the API towards the
# agent as a whole, morphing through negotiation into the best available
# version for each endpoint.

module Datadog
  module Core
    module Remote
      module Transport
        module Negotiation
          # Negotiation request
          class Request < Datadog::Core::Transport::Request
          end

          # Negotiation response
          module Response
            attr_reader :version, :endpoints, :config
          end

          # Negotiation transport
          class Transport
            attr_reader :client, :apis, :default_api, :current_api_id

            def initialize(apis, default_api)
              @apis = apis

              @client = HTTP::Client.new(current_api)
            end

            def send_info
              request = Request.new

              @client.send_info_payload(request)
            end

            def current_api
              @apis[HTTP::API::ROOT]
            end
          end
        end
      end
    end
  end
end
