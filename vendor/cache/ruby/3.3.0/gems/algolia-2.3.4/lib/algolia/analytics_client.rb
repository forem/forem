module Algolia
  module Analytics
    class Client
      include Helpers

      # Initializes the Analytics client
      #
      # @param analytics_config [Analytics::Config] a Analytics::Config object which contains your APP_ID and API_KEY
      # @option adapter [Object] adapter object used for the connection
      # @option logger [Object]
      # @option http_requester [Object] http_requester object used for the connection
      #
      def initialize(analytics_config, opts = {})
        @config      = analytics_config
        adapter      = opts[:adapter] || Defaults::ADAPTER
        logger       = opts[:logger] || LoggerHelper.create
        requester    = opts[:http_requester] || Defaults::REQUESTER_CLASS.new(adapter, logger)
        @transporter = Transport::Transport.new(@config, requester)
      end

      # Create a new client providing only app ID and API key
      #
      # @param app_id [String] Algolia application ID
      # @param api_key [String] Algolia API key
      #
      # @return self
      #
      def self.create(app_id, api_key)
        config = Analytics::Config.new(application_id: app_id, api_key: api_key)
        create_with_config(config)
      end

      # Create a new client providing only an Analytics::Config object
      #
      # @param config [Analytics::Config]
      #
      # @return self
      #
      def self.create_with_config(config)
        new(config)
      end

      # Creates a new A/B test with provided configuration.
      #
      # @param ab_test [Hash]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def add_ab_test(ab_test, opts = {})
        @transporter.write(:POST, '/2/abtests', ab_test, opts)
      end

      # Returns metadata and metrics for A/B test id.
      #
      # @param ab_test_id [Integer] A/B test ID
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def get_ab_test(ab_test_id, opts = {})
        raise AlgoliaError, 'ab_test_id cannot be empty.' if ab_test_id.nil?

        @transporter.read(:GET, path_encode('/2/abtests/%s', ab_test_id), {}, opts)
      end

      # Fetch all existing A/B tests for App that are available for the current API Key.
      # Returns an array of metadata and metrics.
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def get_ab_tests(opts = {})
        @transporter.read(:GET, '/2/abtests', {}, opts)
      end

      # Marks the A/B test as stopped. At this point, the test is over and cannot be restarted
      #
      # @param ab_test_id [Integer] A/B test ID
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def stop_ab_test(ab_test_id, opts = {})
        raise AlgoliaError, 'ab_test_id cannot be empty.' if ab_test_id.nil?

        @transporter.write(:POST, path_encode('/2/abtests/%s/stop', ab_test_id), {}, opts)
      end

      # Deletes the A/B Test and removes all associated metadata & metrics.
      #
      # @param ab_test_id [Integer] A/B test ID
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def delete_ab_test(ab_test_id, opts = {})
        raise AlgoliaError, 'ab_test_id cannot be empty.' if ab_test_id.nil?

        @transporter.write(:DELETE, path_encode('/2/abtests/%s', ab_test_id), {}, opts)
      end
    end
  end
end
