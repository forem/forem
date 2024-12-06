# frozen_string_literal: true
module Excon
  module Middleware
    class ResponseParser < Excon::Middleware::Base
      def response_call(datum)
        unless datum.has_key?(:response)
          datum = Excon::Response.parse(datum[:connection].send(:socket), datum)
        end
        if datum.has_key?(:logger)
          datum[:response][:logger] = datum[:logger]
        end
        @stack.response_call(datum)
      end
    end
  end
end
