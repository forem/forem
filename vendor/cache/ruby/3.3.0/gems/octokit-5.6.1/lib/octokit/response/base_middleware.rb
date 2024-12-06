# frozen_string_literal: true

require 'faraday'

module Octokit
  module Response
    # In Faraday 2.x, Faraday::Response::Middleware was removed
    BaseMiddleware = defined?(Faraday::Response::Middleware) ? Faraday::Response::Middleware : Faraday::Middleware
  end
end
