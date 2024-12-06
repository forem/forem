# frozen_string_literal: true

module Datadog
  module Tracing
    module Transport
      module HTTP
        module API
          # Specification for an HTTP API
          # Defines behaviors without specific configuration details.
          class Spec
            def initialize
              yield(self) if block_given?
            end
          end
        end
      end
    end
  end
end
