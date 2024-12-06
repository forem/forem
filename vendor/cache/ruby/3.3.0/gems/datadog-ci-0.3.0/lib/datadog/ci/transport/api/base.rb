# frozen_string_literal: true

require_relative "../../ext/transport"

module Datadog
  module CI
    module Transport
      module Api
        class Base
          attr_reader :http

          def initialize(http:)
            @http = http
          end

          def request(path:, payload:, verb: "post")
            http.request(
              path: path,
              payload: payload,
              verb: verb,
              headers: headers
            )
          end

          private

          def headers
            {
              Ext::Transport::HEADER_CONTENT_TYPE => Ext::Transport::CONTENT_TYPE_MESSAGEPACK
            }
          end
        end
      end
    end
  end
end
