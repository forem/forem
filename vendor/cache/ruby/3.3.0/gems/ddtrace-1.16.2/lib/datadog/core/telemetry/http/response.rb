module Datadog
  module Core
    module Telemetry
      module Http
        # Module for base HTTP response
        module Response
          def payload
            nil
          end

          def ok?
            nil
          end

          def unsupported?
            nil
          end

          def not_found?
            nil
          end

          def client_error?
            nil
          end

          def server_error?
            nil
          end

          def internal_error?
            nil
          end

          def inspect
            "#{self.class} ok?:#{ok?} unsupported?:#{unsupported?}, " \
            "not_found?:#{not_found?}, client_error?:#{client_error?}, " \
            "server_error?:#{server_error?}, internal_error?:#{internal_error?}, " \
            "payload:#{payload}"
          end
        end

        # A generic error response for internal errors
        class InternalErrorResponse
          include Response

          attr_reader :error

          def initialize(error)
            @error = error
          end

          def internal_error?
            true
          end

          def inspect
            "#{super}, error_type:#{error.class} error:#{error}"
          end
        end
      end
    end
  end
end
