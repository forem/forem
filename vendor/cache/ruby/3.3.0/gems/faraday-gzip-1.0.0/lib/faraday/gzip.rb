# frozen_string_literal: true

require 'faraday'
require_relative 'gzip/middleware'
require_relative 'gzip/version'

module Faraday
  # Middleware main module.
  module Gzip
    Faraday::Request.register_middleware(gzip: Faraday::Gzip::Middleware)
  end
end
