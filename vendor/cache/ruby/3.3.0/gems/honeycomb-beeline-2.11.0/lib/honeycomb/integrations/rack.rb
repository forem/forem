# frozen_string_literal: true

require "rack"
require "honeycomb/integrations/warden"

module Honeycomb
  # Rack specific methods for building middleware
  module Rack
    RACK_FIELDS = [
      ["REQUEST_METHOD", "request.method"],
      ["PATH_INFO", "request.path"],
      ["QUERY_STRING", "request.query_string"],
      ["HTTP_VERSION", "request.http_version"],
      ["HTTP_HOST", "request.host"],
      ["REMOTE_ADDR", "request.remote_addr"],
      ["HTTP_X_FORWARDED_FOR", "request.header.x_forwarded_for"],
      ["HTTP_X_FORWARDED_PROTO", "request.header.x_forwarded_proto"],
      ["HTTP_X_FORWARDED_PORT", "request.header.x_forwarded_port"],
      ["HTTP_ACCEPT", "request.header.accept"],
      ["HTTP_ACCEPT_ENCODING", "request.header.accept_encoding"],
      ["HTTP_ACCEPT_LANGUAGE", "request.header.accept_language"],
      ["CONTENT_TYPE", "request.header.content_type"],
      ["HTTP_USER_AGENT", "request.header.user_agent"],
      ["rack.url_scheme", "request.scheme"],
      ["HTTP_REFERER", "request.header.referer"],
    ].freeze

    attr_reader :app, :client

    def initialize(app, options)
      @app = app
      @client = options[:client]
    end

    def call(env)
      req = ::Rack::Request.new(env)
      client.start_span(
        name: "http_request",
        serialized_trace: env,
      ) do |span|
        add_field = lambda do |key, value|
          unless value.nil? || (value.respond_to?(:empty?) && value.empty?)
            span.add_field(key, value)
          end
        end

        extract_fields(env, RACK_FIELDS, &add_field)

        span.add_field("request.secure", req.ssl?)
        span.add_field("request.xhr", req.xhr?)

        begin
          status, headers, body = call_with_hook(env, span, &add_field)
        ensure
          add_package_information(env, &add_field)
          extract_user_information(env, &add_field)
        end

        span.add_field("response.status_code", status)
        span.add_field("response.content_type", headers["Content-Type"])

        [status, headers, body]
      end
    end

    def add_package_information(_env)
      yield "meta.package", "rack"
      yield "meta.package_version", ::Rack::VERSION.join(".")
    end

    def extract_fields(env, fields)
      fields.each do |key, value|
        yield value, env[key]
      end
    end

    private

    def call_with_hook(env, _span, &_add_field)
      app.call(env)
    end

    # Rack middleware
    class Middleware
      include Rack
      include Warden
    end
  end
end
