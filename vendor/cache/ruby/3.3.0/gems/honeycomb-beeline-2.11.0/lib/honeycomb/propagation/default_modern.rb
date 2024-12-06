# frozen_string_literal: true

require "honeycomb/propagation/honeycomb_modern"
require "honeycomb/propagation/w3c"

module Honeycomb
  # Default behavior for handling trace propagation
  module DefaultModernPropagation
    # Parse incoming trace headers.
    #
    # Checks for and parses Honeycomb's trace header or, if not found,
    # then checks for and parses W3C trace parent header.
    module UnmarshalTraceContext
      def parse_rack_env(env)
        if env["HTTP_X_HONEYCOMB_TRACE"]
          HoneycombModernPropagation::UnmarshalTraceContext.parse_rack_env env
        elsif env["HTTP_TRACEPARENT"]
          W3CPropagation::UnmarshalTraceContext.parse_rack_env env
        else
          [nil, nil, nil, nil]
        end
      end
      # rubocop:disable Style/AccessModifierDeclarations
      module_function :parse_rack_env
      public :parse_rack_env
      # rubocop:enable Style/AccessModifierDeclarations
    end
  end
end
