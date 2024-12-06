module Algolia
  module Http
    class HttpRequester
      include Helpers
      attr_accessor :adapter, :logger

      #
      # @param adapter [Object] adapter used to make requests. Defaults to Net::Http
      # @param logger [Object] logger used to log requests. Defaults to Algolia::LoggerHelper
      #
      def initialize(adapter, logger)
        @adapter     = adapter
        @logger      = logger
        @connections = {}
      end

      # Sends request to the engine
      #
      # @param host [StatefulHost]
      # @param method [Symbol]
      # @param path [String]
      # @param body [JSON]
      # @param headers [Hash]
      #
      # @return [Http::Response]
      #
      def send_request(host, method, path, body, headers, timeout, connect_timeout)
        connection                      = connection(host)
        connection.options.timeout      = timeout
        connection.options.open_timeout = connect_timeout

        if ENV['ALGOLIA_DEBUG']
          @logger.info("Sending #{method.to_s.upcase!} request to #{path} with body #{body}")
        end

        response = connection.run_request(method, path, body, headers)

        if response.success?
          if ENV['ALGOLIA_DEBUG']
            @logger.info("Request succeeded. Response status: #{response.status}, body: #{response.body}")
          end
          return Http::Response.new(status: response.status, body: response.body, headers: response.headers)
        end

        if ENV['ALGOLIA_DEBUG']
          @logger.info("Request failed. Response status: #{response.status}, error: #{response.body}")
        end
        Http::Response.new(status: response.status, error: response.body, headers: response.headers)
      rescue Faraday::TimeoutError => e
        if ENV['ALGOLIA_DEBUG']
          @logger.info("Request timed out. Error: #{e.message}")
        end
        Http::Response.new(error: e.message, has_timed_out: true)
      rescue ::StandardError => e
        if ENV['ALGOLIA_DEBUG']
          @logger.info("Request failed. Error: #{e.message}")
        end
        Http::Response.new(error: e.message, network_failure: true)
      end

      # Retrieve the connection from the @connections
      #
      # @param host [StatefulHost]
      #
      # @return [Faraday::Connection]
      #
      def connection(host)
        @connections[host.url] ||= Faraday.new(build_url(host)) do |f|
          f.adapter @adapter.to_sym
        end
      end

      # Build url from host, path and parameters
      #
      # @param host [StatefulHost]
      #
      # @return [String]
      #
      def build_url(host)
        host.protocol + host.url
      end
    end
  end
end
