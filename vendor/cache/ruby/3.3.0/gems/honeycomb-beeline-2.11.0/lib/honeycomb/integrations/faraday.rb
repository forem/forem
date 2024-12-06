# frozen_string_literal: true

require "faraday"

module Honeycomb
  # Faraday middleware to create spans around outgoing http requests
  class Faraday < ::Faraday::Middleware
    def initialize(app, options)
      super(app)
      @client = options[:client]
    end

    def call(env)
      return @app.call(env) if @client.nil?

      @client.start_span(name: "http_client") do |span|
        span.add_field "request.method", env.method.upcase
        span.add_field "request.scheme", env.url.scheme
        span.add_field "request.host", env.url.host
        span.add_field "request.path", env.url.path
        span.add_field "meta.type", "http_client"
        span.add_field "meta.package", "faraday"
        span.add_field "meta.package_version", ::Faraday::VERSION

        if (headers = span.trace_headers(env)).is_a?(Hash)
          env.request_headers.merge!(headers)
        end

        @app.call(env).tap do |response|
          span.add_field "response.status_code", response.status
        end
      end
    end
  end
end

::Faraday::Connection.module_eval do
  alias_method :standard_initialize, :initialize

  def initialize(url = nil, options = nil, &block)
    standard_initialize(url, options, &block)

    return if @builder.handlers.include? Honeycomb::Faraday

    adapter_index = @builder.handlers.find_index do |handler|
      handler.klass.ancestors.include? Faraday::Adapter
    end

    if adapter_index
      @builder.insert_before(
        adapter_index,
        Honeycomb::Faraday,
        client: Honeycomb.client,
      )
    else
      @builder.use(Honeycomb::Faraday, client: Honeycomb.client)
    end
  end
end

Faraday::Middleware.register_middleware honeycomb: -> { Honeycomb::Faraday }
