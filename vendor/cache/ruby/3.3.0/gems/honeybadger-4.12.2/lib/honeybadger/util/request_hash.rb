require 'set'

module Honeybadger
  module Util
    # Constructs a request hash from a Rack::Request matching the /v1/notices
    # API specification.
    module RequestHash
      HTTP_HEADER_PREFIX = 'HTTP_'.freeze

      CGI_WHITELIST = %w(
        AUTH_TYPE
        CONTENT_LENGTH
        CONTENT_TYPE
        GATEWAY_INTERFACE
        HTTPS
        REMOTE_ADDR
        REMOTE_HOST
        REMOTE_IDENT
        REMOTE_USER
        REQUEST_METHOD
        SERVER_NAME
        SERVER_PORT
        SERVER_PROTOCOL
        SERVER_SOFTWARE
      ).freeze

      def self.from_env(env)
        return {} unless defined?(::Rack::Request)
        return {} unless env

        hash, request = {}, ::Rack::Request.new(env.dup)

        hash[:url] = extract_url(request)
        hash[:params] = extract_params(request)
        hash[:component] = hash[:params]['controller']
        hash[:action] = hash[:params]['action']
        hash[:session] = extract_session(request)
        hash[:cgi_data] = extract_cgi_data(request)

        hash
      end

      def self.extract_url(request)
        request.env['honeybadger.request.url'] || request.url
      rescue => e
        "Failed to access URL -- #{e}"
      end

      def self.extract_params(request)
        (request.env['action_dispatch.request.parameters'] || request.params).to_hash || {}
      rescue => e
        { error: "Failed to access params -- #{e}" }
      end

      def self.extract_session(request)
        request.session.to_hash
      rescue => e
        # Rails raises ArgumentError when `config.secret_token` is missing, and
        # ActionDispatch::Session::SessionRestoreError when the session can't be
        # restored.
        { error: "Failed to access session data -- #{e}" }
      end

      def self.extract_cgi_data(request)
        request.env.each_with_object({}) do |(k,v), env|
          next unless k.is_a?(String)
          next unless k.start_with?(HTTP_HEADER_PREFIX) || CGI_WHITELIST.include?(k)
          env[k] = v
        end
      end
    end
  end
end
