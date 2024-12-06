require_relative '../../../core/header_collection'

module Datadog
  module Tracing
    module Contrib
      module Rack
        # Classes and utilities for handling headers in Rack.
        module Header
          # An implementation of a header collection that looks up headers from a Rack environment.
          class RequestHeaderCollection < Datadog::Core::HeaderCollection
            # Creates a header collection from a rack environment.
            def initialize(env)
              super()
              @env = env
            end

            # Gets the value of the header with the given name.
            def get(header_name)
              @env[Header.to_rack_header(header_name)]
            end

            # Allows this class to have a similar API to a {Hash}.
            alias [] get

            # Tests whether a header with the given name exists in the environment.
            def key?(header_name)
              @env.key?(Header.to_rack_header(header_name))
            end
          end

          def self.to_rack_header(name)
            "HTTP_#{name.to_s.upcase.gsub(/[-\s]/, '_')}"
          end
        end
      end
    end
  end
end
