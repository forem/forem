# frozen_string_literal: true

module Octokit
  # Authentication methods for {Octokit::Client}
  module Authentication
    # In Faraday 2.x, the authorization middleware uses new interface
    FARADAY_BASIC_AUTH_KEYS =
      if Gem::Version.new(Faraday::VERSION) >= Gem::Version.new('2.0')
        %i[authorization basic]
      else
        [:basic_auth]
      end

    # Indicates if the client was supplied  Basic Auth
    # username and password
    #
    # @see https://developer.github.com/v3/#authentication
    # @return [Boolean]
    def basic_authenticated?
      !!(@login && @password)
    end

    # Indicates if the client was supplied an OAuth
    # access token
    #
    # @see https://developer.github.com/v3/#authentication
    # @return [Boolean]
    def token_authenticated?
      !!@access_token
    end

    # Indicates if the client was supplied a bearer token
    #
    # @see https://developer.github.com/early-access/integrations/authentication/#as-an-integration
    # @return [Boolean]
    def bearer_authenticated?
      !!@bearer_token
    end

    # Indicates if the client was supplied an OAuth
    # access token or Basic Auth username and password
    #
    # @see https://developer.github.com/v3/#authentication
    # @return [Boolean]
    def user_authenticated?
      basic_authenticated? || token_authenticated?
    end

    # Indicates if the client has OAuth Application
    # client_id and secret credentials to make anonymous
    # requests at a higher rate limit
    #
    # @see https://developer.github.com/v3/#unauthenticated-rate-limited-requests
    # @return [Boolean]
    def application_authenticated?
      !!(@client_id && @client_secret)
    end

    private

    def login_from_netrc
      return unless netrc?

      require 'netrc'
      info = Netrc.read netrc_file
      netrc_host = URI.parse(api_endpoint).host
      creds = info[netrc_host]
      if creds.nil?
        # creds will be nil if there is no netrc for this end point
        octokit_warn "Error loading credentials from netrc file for #{api_endpoint}"
      else
        creds = creds.to_a
        self.login = creds.shift
        self.password = creds.shift
      end
    rescue LoadError
      octokit_warn 'Please install netrc gem for .netrc support'
    end
  end
end
