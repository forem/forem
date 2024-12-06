# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require "cgi"
require "json"
require "uri"

require_relative "persistent"
require_relative "configurable"
require_relative "errors"
require_relative "version"
require_relative "encode"

module Vault
  class Client
    # The user agent for this client.
    USER_AGENT = "VaultRuby/#{Vault::VERSION} (+github.com/hashicorp/vault-ruby)".freeze

    # The name of the header used to hold the Vault token.
    TOKEN_HEADER = "X-Vault-Token".freeze

    # The name of the header used to hold the Namespace.
    NAMESPACE_HEADER = "X-Vault-Namespace".freeze

    # The name of the header used to hold the wrapped request ttl.
    WRAP_TTL_HEADER = "X-Vault-Wrap-TTL".freeze

    # The name of the header used for redirection.
    LOCATION_HEADER = "location".freeze

    # The default headers that are sent with every request.
    DEFAULT_HEADERS = {
      "Content-Type" => "application/json",
      "Accept"       => "application/json",
      "User-Agent"   => USER_AGENT,
    }.freeze

    # The default list of options to use when parsing JSON.
    JSON_PARSE_OPTIONS = {
      max_nesting:      false,
      create_additions: false,
      symbolize_names:  true,
    }.freeze

    RESCUED_EXCEPTIONS = [].tap do |a|
      # Failure to even open the socket (usually permissions)
      a << SocketError

      # Failed to reach the server (aka bad URL)
      a << Errno::ECONNREFUSED
      a << Errno::EADDRNOTAVAIL

      # Failed to read body or no response body given
      a << EOFError

      # Timeout (Ruby 1.9-)
      a << Timeout::Error

      # Timeout (Ruby 1.9+) - Ruby 1.9 does not define these constants so we
      # only add them if they are defiend
      a << Net::ReadTimeout if defined?(Net::ReadTimeout)
      a << Net::OpenTimeout if defined?(Net::OpenTimeout)

      a << PersistentHTTP::Error
    end.freeze

    # Vault requires at least TLS1.2
    MIN_TLS_VERSION = if defined? OpenSSL::SSL::TLS1_2_VERSION
                        OpenSSL::SSL::TLS1_2_VERSION
                      else
                        "TLSv1_2"
                      end

    include Vault::Configurable

    # Create a new Client with the given options. Any options given take
    # precedence over the default options.
    #
    # @return [Vault::Client]
    def initialize(options = {})
      # Use any options given, but fall back to the defaults set on the module
      Vault::Configurable.keys.each do |key|
        value = options.key?(key) ? options[key] : Defaults.public_send(key)
        instance_variable_set(:"@#{key}", value)
      end

      @lock = Mutex.new
      @nhp = nil
    end

    def pool
      @lock.synchronize do
        return @nhp if @nhp

        @nhp = PersistentHTTP.new("vault-ruby", nil, pool_size, pool_timeout)

        if proxy_address
          proxy_uri = URI.parse "http://#{proxy_address}"

          proxy_uri.port = proxy_port if proxy_port

          if proxy_username
            proxy_uri.user = proxy_username
            proxy_uri.password = proxy_password
          end

          @nhp.proxy = proxy_uri
        end

        # Use a custom open timeout
        if open_timeout || timeout
          @nhp.open_timeout = (open_timeout || timeout).to_i
        end

        # Use a custom read timeout
        if read_timeout || timeout
          @nhp.read_timeout = (read_timeout || timeout).to_i
        end

        @nhp.verify_mode = OpenSSL::SSL::VERIFY_PEER

        @nhp.min_version = MIN_TLS_VERSION

        # Only use secure ciphers
        @nhp.ciphers = ssl_ciphers

        # Custom pem files, no problem!
        pem = ssl_pem_contents || (ssl_pem_file ? File.read(ssl_pem_file) : nil)
        if pem
          @nhp.cert = OpenSSL::X509::Certificate.new(pem)
          @nhp.key = OpenSSL::PKey::RSA.new(pem, ssl_pem_passphrase)
        end

        # Use custom CA cert for verification
        if ssl_ca_cert
          @nhp.ca_file = ssl_ca_cert
        end

        # Use custom CA path that contains CA certs
        if ssl_ca_path
          @nhp.ca_path = ssl_ca_path
        end

        if ssl_cert_store
          @nhp.cert_store = ssl_cert_store
        end

        # Naughty, naughty, naughty! Don't blame me when someone hops in
        # and executes a MITM attack!
        if !ssl_verify
          @nhp.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        # Use custom timeout for connecting and verifying via SSL
        if ssl_timeout || timeout
          @nhp.ssl_timeout = (ssl_timeout || timeout).to_i
        end

        @nhp
      end
    end

    private :pool

    # Shutdown any open pool connections. Pool will be recreated upon next request.
    def shutdown
      @nhp.shutdown()
      @nhp = nil
    end

    # Creates and yields a new client object with the given token. This may be
    # used safely in a threadsafe manner because the original client remains
    # unchanged. The value of the block is returned.
    #
    # @yield [Vault::Client]
    def with_token(token)
      client = self.dup
      client.token = token
      return yield client if block_given?
      return nil
    end

    # Determine if the given options are the same as ours.
    # @return [true, false]
    def same_options?(opts)
      options.hash == opts.hash
    end

    # Perform a GET request.
    # @see Client#request
    def get(path, params = {}, headers = {})
      request(:get, path, params, headers)
    end

    # Perform a LIST request.
    # @see Client#request
    def list(path, params = {}, headers = {})
      params = params.merge(list: true)
      request(:get, path, params, headers)
    end

    # Perform a POST request.
    # @see Client#request
    def post(path, data = {}, headers = {})
      request(:post, path, data, headers)
    end

    # Perform a PUT request.
    # @see Client#request
    def put(path, data, headers = {})
      request(:put, path, data, headers)
    end

    # Perform a PATCH request.
    # @see Client#request
    def patch(path, data, headers = {})
      request(:patch, path, data, headers)
    end

    # Perform a DELETE request.
    # @see Client#request
    def delete(path, params = {}, headers = {})
      request(:delete, path, params, headers)
    end

    # Make an HTTP request with the given verb, data, params, and headers. If
    # the response has a return type of JSON, the JSON is automatically parsed
    # and returned as a hash; otherwise it is returned as a string.
    #
    # @raise [HTTPError]
    #   if the request is not an HTTP 200 OK
    #
    # @param [Symbol] verb
    #   the lowercase symbol of the HTTP verb (e.g. :get, :delete)
    # @param [String] path
    #   the absolute or relative path from {Defaults.address} to make the
    #   request against
    # @param [#read, Hash, nil] data
    #   the data to use (varies based on the +verb+)
    # @param [Hash] headers
    #   the list of headers to use
    #
    # @return [String, Hash]
    #   the response body
    def request(verb, path, data = {}, headers = {})
      # Build the URI and request object from the given information
      uri = build_uri(verb, path, data)
      request = class_for_request(verb).new(uri.request_uri)
      if uri.userinfo()
        request.basic_auth uri.user, uri.password
      end

      # Get a list of headers
      headers = DEFAULT_HEADERS.merge(headers)

      # Add the Vault token header - users could still override this on a
      # per-request basis
      if !token.nil?
        headers[TOKEN_HEADER] ||= token
      end

      # Add the Vault Namespace header - users could still override this on a
      # per-request basis
      if !namespace.nil?
        headers[NAMESPACE_HEADER] ||= namespace
      end

      # Add headers
      headers.each do |key, value|
        request.add_field(key, value)
      end

      # Setup PATCH/POST/PUT
      if [:patch, :post, :put].include?(verb)
        if data.respond_to?(:read)
          request.content_length = data.size
          request.body_stream = data
        elsif data.is_a?(Hash)
          request.form_data = data
        else
          request.body = data
        end
      end

      begin
        # Create a connection using the block form, which will ensure the socket
        # is properly closed in the event of an error.
        response = pool.request(uri, request)

        case response
        when Net::HTTPRedirection
          # On a redirect of a GET or HEAD request, the URL already contains
          # the data as query string parameters.
          if [:head, :get].include?(verb)
            data = {}
          end
          request(verb, response[LOCATION_HEADER], data, headers)
        when Net::HTTPSuccess
          success(response)
        else
          error(response)
        end
      rescue *RESCUED_EXCEPTIONS => e
        raise HTTPConnectionError.new(address, e)
      end
    end

    # Construct a URL from the given verb and path. If the request is a GET or
    # DELETE request, the params are assumed to be query params are are
    # converted as such using {Client#to_query_string}.
    #
    # If the path is relative, it is merged with the {Defaults.address}
    # attribute. If the path is absolute, it is converted to a URI object and
    # returned.
    #
    # @param [Symbol] verb
    #   the lowercase HTTP verb (e.g. :+get+)
    # @param [String] path
    #   the absolute or relative HTTP path (url) to get
    # @param [Hash] params
    #   the list of params to build the URI with (for GET and DELETE requests)
    #
    # @return [URI]
    def build_uri(verb, path, params = {})
      # Add any query string parameters
      if [:delete, :get].include?(verb)
        path = [path, to_query_string(params)].compact.join("?")
      end

      # Parse the URI
      uri = URI.parse(path)

      # Don't merge absolute URLs
      uri = URI.parse(File.join(address, path)) unless uri.absolute?

      # Return the URI object
      uri
    end

    # Helper method to get the corresponding {Net::HTTP} class from the given
    # HTTP verb.
    #
    # @param [#to_s] verb
    #   the HTTP verb to create a class from
    #
    # @return [Class]
    def class_for_request(verb)
      Net::HTTP.const_get(verb.to_s.capitalize)
    end

    # Convert the given hash to a list of query string parameters. Each key and
    # value in the hash is URI-escaped for safety.
    #
    # @param [Hash] hash
    #   the hash to create the query string from
    #
    # @return [String, nil]
    #   the query string as a string, or +nil+ if there are no params
    def to_query_string(hash)
      hash.map do |key, value|
        "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
      end.join('&')[/.+/]
    end

    # Parse the response object and manipulate the result based on the given
    # +Content-Type+ header. For now, this method only parses JSON, but it
    # could be expanded in the future to accept other content types.
    #
    # @param [HTTP::Message] response
    #   the response object from the request
    #
    # @return [String, Hash]
    #   the parsed response, as an object
    def success(response)
      if response.body && (response.content_type || '').include?("json")
        JSON.parse(response.body, JSON_PARSE_OPTIONS)
      else
        response.body
      end
    end

    # Raise a response error, extracting as much information from the server's
    # response as possible.
    #
    # @raise [HTTPError]
    #
    # @param [HTTP::Message] response
    #   the response object from the request
    def error(response)
      if response.body && response.body.match("missing client token")
        # Vault 1.10+ no longer returns "missing" client token" so we use HTTPClientError
        klass = HTTPClientError
      else
        # Use the correct exception class
        case response
        when Net::HTTPPreconditionFailed
          raise MissingRequiredStateError.new
        when Net::HTTPClientError
          klass = HTTPClientError
        when Net::HTTPServerError
          klass = HTTPServerError
        else
          klass = HTTPError
        end
      end

      if (response.content_type || '').include?("json")
        # Attempt to parse the error as JSON
        begin
          json = JSON.parse(response.body, JSON_PARSE_OPTIONS)

          if json[:errors]
            raise klass.new(address, response, json[:errors])
          end
        rescue JSON::ParserError; end
      end

      raise klass.new(address, response, [response.body])
    end

    # Execute the given block with retries and exponential backoff.
    #
    # @param [Array<Exception>] rescued
    #   the list of exceptions to rescue
    def with_retries(*rescued, &block)
      options      = rescued.last.is_a?(Hash) ? rescued.pop : {}
      exception    = nil
      retries      = 0

      rescued = Defaults::RETRIED_EXCEPTIONS if rescued.empty?

      max_attempts = options[:attempts] || Defaults::RETRY_ATTEMPTS
      backoff_base = options[:base]     || Defaults::RETRY_BASE
      backoff_max  = options[:max_wait] || Defaults::RETRY_MAX_WAIT

      begin
        return yield retries, exception
      rescue *rescued => e
        exception = e

        retries += 1
        raise if retries > max_attempts

        # Calculate the exponential backoff combined with an element of
        # randomness.
        backoff = [backoff_base * (2 ** (retries - 1)), backoff_max].min
        backoff = backoff * (0.5 * (1 + Kernel.rand))

        # Ensure we are sleeping at least the minimum interval.
        backoff = [backoff_base, backoff].max

        # Exponential backoff.
        Kernel.sleep(backoff)

        # Now retry
        retry
      end
    end
  end
end
