module Algolia
  module Personalization
    class Client
      # Initializes the Personalization client
      #
      # @param personalization_config [Personalization::Config] a Personalization::Config object which contains your APP_ID and API_KEY
      # @option adapter [Object] adapter object used for the connection
      # @option logger [Object]
      # @option http_requester [Object] http_requester object used for the connection
      #
      def initialize(personalization_config, opts = {})
        @config      = personalization_config
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
        config = Personalization::Config.new(application_id: app_id, api_key: api_key)
        create_with_config(config)
      end

      # Create a new client providing only an Personalization::Config object
      #
      # @param config [Personalization::Config]
      #
      # @return self
      #
      def self.create_with_config(config)
        new(config)
      end

      # Set the personalization strategy.
      #
      # @param personalization_strategy [Hash] A strategy object.
      #
      # @return [Hash]
      #
      def set_personalization_strategy(personalization_strategy, opts = {})
        @transporter.write(:POST, '1/strategies/personalization', personalization_strategy, opts)
      end

      # Get the personalization strategy.
      #
      # @return [Hash]
      #
      def get_personalization_strategy(opts = {})
        @transporter.read(:GET, '1/strategies/personalization', {}, opts)
      end
    end
  end
end
