# frozen_string_literal: true

require 'octokit/response/base_middleware'
require 'octokit/error'

module Octokit
  # Faraday response middleware
  module Response
    # This class raises an Octokit-flavored exception based
    # HTTP status codes returned by the API
    class RaiseError < BaseMiddleware
      def on_complete(response)
        if error = Octokit::Error.from_response(response)
          raise error
        end
      end
    end
  end
end
