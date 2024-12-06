# frozen_string_literal: true

require "honeycomb/propagation/honeycomb"
require "honeycomb/propagation/w3c"

module Honeycomb
  # Default behavior for handling trace propagation
  module DefaultPropagation
    # Parse incoming trace headers.
    #
    # Checks for and parses Honeycomb's trace header or, if not found,
    # then checks for and parses W3C trace parent header.
    module UnmarshalTraceContext
      def parse_rack_env(env)
        if env["HTTP_X_HONEYCOMB_TRACE"]
          HoneycombPropagation::UnmarshalTraceContext.parse_rack_env env
        elsif env["HTTP_TRACEPARENT"]
          W3CPropagation::UnmarshalTraceContext.parse_rack_env env
        else
          [nil, nil, nil, nil]
        end
      end
      module_function :parse_rack_env
      public :parse_rack_env
    end
  end
end
