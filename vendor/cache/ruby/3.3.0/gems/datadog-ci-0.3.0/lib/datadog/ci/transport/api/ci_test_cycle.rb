# frozen_string_literal: true

require_relative "base"
require_relative "../../ext/transport"

module Datadog
  module CI
    module Transport
      module Api
        class CiTestCycle < Base
          attr_reader :api_key

          def initialize(api_key:, http:)
            @api_key = api_key

            super(http: http)
          end

          private

          def headers
            headers = super
            headers[Ext::Transport::HEADER_DD_API_KEY] = api_key
            headers
          end
        end
      end
    end
  end
end
