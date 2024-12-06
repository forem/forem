# frozen_string_literal: true

module Datadog
  module Core
    module Telemetry
      module Http
        # Data structure for an HTTP request
        class Env
          attr_accessor :path, :body

          attr_writer :headers

          def headers
            @headers ||= {}
          end
        end
      end
    end
  end
end
