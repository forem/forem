require 'faraday'
# this is the default adapter and it needs to be required to be registered.
require 'faraday/net_http_persistent' unless Faraday::VERSION < '1'

module Algolia
  module Transport
    class Transport
      include RetryOutcomeType
      include CallType
      include Helpers

      # @param config [Search::Config] config used for search
      # @param requester [Object] requester used for sending requests. Uses Algolia::Http::HttpRequester by default
      #
      def initialize(config, requester)
        @config           = config
        @http_requester   = requester
        @retry_strategy   = RetryStrategy.new(config)
      end

      # Build a request with call type READ
      #
      # @param method [Symbol] method used for request
      # @param path [String] path of the request
      # @param body [Hash] request body
      # @param opts [Hash] contains extra parameters to send with your query
      #
      def read(method, path, body = {}, opts = {})
        request(READ, method, path, body, opts)
      end

      # Build a request with call type WRITE
      #
      # @param method [Symbol] method used for request
      # @param path [String] path of the request
      # @param body [Hash] request body
      # @param opts [Hash] contains extra parameters to send with your query
      #
      def write(method, path, body = {}, opts = {})
        request(WRITE, method, path, body, opts)
      end

      # @param call_type [Binary] READ or WRITE operation
      # @param method [Symbol] method used for request
      # @param path [String] path of the request
      # @param body [Hash] request body
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Response] response of the request
      #
      def request(call_type, method, path, body = {}, opts = {})
        @retry_strategy.get_tryable_hosts(call_type).each do |host|
          opts[:timeout]         ||= get_timeout(call_type) * (host.retry_count + 1)
          opts[:connect_timeout] ||= @config.connect_timeout * (host.retry_count + 1)

          request_options = RequestOptions.new(@config)
          request_options.create(opts)
          request_options.params.merge!(request_options.data) if method == :GET

          request  = build_request(method, path, body, request_options)
          response = @http_requester.send_request(
            host,
            request[:method],
            request[:path],
            request[:body],
            request[:headers],
            request[:timeout],
            request[:connect_timeout]
          )

          outcome  = @retry_strategy.decide(host, http_response_code: response.status, is_timed_out: response.has_timed_out, network_failure: response.network_failure)
          if outcome == FAILURE
            decoded_error = json_to_hash(response.error, @config.symbolize_keys)
            raise AlgoliaHttpError.new(get_option(decoded_error, 'status'), get_option(decoded_error, 'message'))
          end
          return json_to_hash(response.body, @config.symbolize_keys) unless outcome == RETRY
        end

        raise AlgoliaUnreachableHostError, 'Unreachable hosts'
      end

      private

      # Parse the different information and build the request
      #
      # @param [Symbol] method
      # @param [String] path
      # @param [Hash] body
      # @param [RequestOptions] request_options
      #
      # @return [Hash]
      #
      def build_request(method, path, body, request_options)
        request                   = {}
        request[:method]          = method.downcase
        request[:path]            = build_uri_path(path, request_options.params)
        request[:body]            = build_body(body, request_options, method)
        request[:headers]         = generate_headers(request_options)
        request[:timeout]         = request_options.timeout
        request[:connect_timeout] = request_options.connect_timeout
        request
      end

      # Build the uri from path and additional params
      #
      # @param [Object] path
      # @param [Object] params
      #
      # @return [String]
      #
      def build_uri_path(path, params)
        path + handle_params(params)
      end

      # Build the body of the request
      #
      # @param [Hash] body
      #
      # @return [Hash]
      #
      def build_body(body, request_options, method)
        if method == :GET && body.empty?
          return nil
        end

        # merge optional special request options to the body when it
        # doesn't have to be in the array format
        body.merge!(request_options.data) if body.is_a?(Hash) && method != :GET
        to_json(body)
      end

      # Generates headers from config headers and optional parameters
      #
      # @param request_options [RequestOptions]
      #
      # @return [Hash] merged headers
      #
      def generate_headers(request_options = {})
        headers = @config.headers.merge(request_options.headers)
        if request_options.compression_type == Defaults::GZIP_ENCODING
          headers['Accept-Encoding']  = Defaults::GZIP_ENCODING
        end
        headers
      end

      # Retrieves a timeout according to call_type
      #
      # @param call_type [Binary] requested call type
      #
      # @return [Integer]
      #
      def get_timeout(call_type)
        case call_type
        when READ
          @config.read_timeout
        else
          @config.write_timeout
        end
      end
    end
  end
end
