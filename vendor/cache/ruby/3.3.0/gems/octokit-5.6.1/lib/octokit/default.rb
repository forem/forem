# frozen_string_literal: true

require 'octokit/middleware/follow_redirects'
require 'octokit/response/raise_error'
require 'octokit/response/feed_parser'
require 'octokit/version'
require 'octokit/warnable'

if Gem::Version.new(Faraday::VERSION) >= Gem::Version.new('2.0')
  begin
    require 'faraday/retry'
  rescue LoadError
    Octokit::Warnable.octokit_warn 'To use retry middleware with Faraday v2.0+, install `faraday-retry` gem'
  end
end

module Octokit
  # Default configuration options for {Client}
  module Default
    # Default API endpoint
    API_ENDPOINT = 'https://api.github.com'

    # Default User Agent header string
    USER_AGENT   = "Octokit Ruby Gem #{Octokit::VERSION}"

    # Default media type
    MEDIA_TYPE   = 'application/vnd.github.v3+json'

    # Default WEB endpoint
    WEB_ENDPOINT = 'https://github.com'

    # Default Faraday middleware stack
    MIDDLEWARE = Faraday::RackBuilder.new do |builder|
      # In Faraday 2.x, Faraday::Request::Retry was moved to a separate gem
      # so we use it only when it's available.
      if defined?(Faraday::Request::Retry)
        builder.use Faraday::Request::Retry, exceptions: [Octokit::ServerError]
      elsif defined?(Faraday::Retry::Middleware)
        builder.use Faraday::Retry::Middleware, exceptions: [Octokit::ServerError]
      end

      builder.use Octokit::Middleware::FollowRedirects
      builder.use Octokit::Response::RaiseError
      builder.use Octokit::Response::FeedParser
      builder.adapter Faraday.default_adapter
    end

    class << self
      # Configuration options
      # @return [Hash]
      def options
        Octokit::Configurable.keys.map { |key| [key, send(key)] }.to_h
      end

      # Default access token from ENV
      # @return [String]
      def access_token
        ENV.fetch('OCTOKIT_ACCESS_TOKEN', nil)
      end

      # Default API endpoint from ENV or {API_ENDPOINT}
      # @return [String]
      def api_endpoint
        ENV.fetch('OCTOKIT_API_ENDPOINT') { API_ENDPOINT }
      end

      # Default pagination preference from ENV
      # @return [String]
      def auto_paginate
        ENV.fetch('OCTOKIT_AUTO_PAGINATE', nil)
      end

      # Default bearer token from ENV
      # @return [String]
      def bearer_token
        ENV.fetch('OCTOKIT_BEARER_TOKEN', nil)
      end

      # Default OAuth app key from ENV
      # @return [String]
      def client_id
        ENV.fetch('OCTOKIT_CLIENT_ID', nil)
      end

      # Default OAuth app secret from ENV
      # @return [String]
      def client_secret
        ENV.fetch('OCTOKIT_SECRET', nil)
      end

      # Default management console password from ENV
      # @return [String]
      def management_console_password
        ENV.fetch('OCTOKIT_ENTERPRISE_MANAGEMENT_CONSOLE_PASSWORD', nil)
      end

      # Default management console endpoint from ENV
      # @return [String]
      def management_console_endpoint
        ENV.fetch('OCTOKIT_ENTERPRISE_MANAGEMENT_CONSOLE_ENDPOINT', nil)
      end

      # Default options for Faraday::Connection
      # @return [Hash]
      def connection_options
        {
          headers: {
            accept: default_media_type,
            user_agent: user_agent
          }
        }
      end

      # Default media type from ENV or {MEDIA_TYPE}
      # @return [String]
      def default_media_type
        ENV.fetch('OCTOKIT_DEFAULT_MEDIA_TYPE') { MEDIA_TYPE }
      end

      # Default GitHub username for Basic Auth from ENV
      # @return [String]
      def login
        ENV.fetch('OCTOKIT_LOGIN', nil)
      end

      # Default middleware stack for Faraday::Connection
      # from {MIDDLEWARE}
      # @return [Faraday::RackBuilder or Faraday::Builder]
      def middleware
        MIDDLEWARE
      end

      # Default GitHub password for Basic Auth from ENV
      # @return [String]
      def password
        ENV.fetch('OCTOKIT_PASSWORD', nil)
      end

      # Default pagination page size from ENV
      # @return [Integer] Page size
      def per_page
        page_size = ENV.fetch('OCTOKIT_PER_PAGE', nil)

        page_size&.to_i
      end

      # Default proxy server URI for Faraday connection from ENV
      # @return [String]
      def proxy
        ENV.fetch('OCTOKIT_PROXY', nil)
      end

      # Default SSL verify mode from ENV
      # @return [Integer]
      def ssl_verify_mode
        # 0 is OpenSSL::SSL::VERIFY_NONE
        # 1 is OpenSSL::SSL::SSL_VERIFY_PEER
        # the standard default for SSL is SSL_VERIFY_PEER which requires a server certificate check on the client
        ENV.fetch('OCTOKIT_SSL_VERIFY_MODE', 1).to_i
      end

      # Default User-Agent header string from ENV or {USER_AGENT}
      # @return [String]
      def user_agent
        ENV.fetch('OCTOKIT_USER_AGENT') { USER_AGENT }
      end

      # Default web endpoint from ENV or {WEB_ENDPOINT}
      # @return [String]
      def web_endpoint
        ENV.fetch('OCTOKIT_WEB_ENDPOINT') { WEB_ENDPOINT }
      end

      # Default behavior for reading .netrc file
      # @return [Boolean]
      def netrc
        ENV.fetch('OCTOKIT_NETRC', false)
      end

      # Default path for .netrc file
      # @return [String]
      def netrc_file
        ENV.fetch('OCTOKIT_NETRC_FILE') { File.join(Dir.home.to_s, '.netrc') }
      end
    end
  end
end
