module Algolia
  module Insights
    class Client
      include Helpers

      # Initializes the Insights client
      #
      # @param insights_config [Insights::Config] an Insights::Config object which contains your APP_ID and API_KEY
      # @option adapter [Object] adapter object used for the connection
      # @option logger [Object]
      # @option http_requester [Object] http_requester object used for the connection
      #
      def initialize(insights_config, opts = {})
        @config      = insights_config
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
        config = Insights::Config.new(application_id: app_id, api_key: api_key)
        create_with_config(config)
      end

      # Create a new client providing only an Analytics::Config object
      #
      # @param config [Insights::Config]
      #
      # @return self
      #
      def self.create_with_config(config)
        new(config)
      end

      # Create a new Insight User Client
      #
      # @param user_token [String]
      #
      # @return [UserClient]
      #
      def user(user_token)
        UserClient.new(self, user_token)
      end

      # Push an event to the Insights API.
      #
      # @param event [Hash]
      #
      # @return [Hash]
      #
      def send_event(event, opts = {})
        send_events([event], opts)
      end

      # Push an array of events to the Insights API.
      #
      # @param events [Array]
      #
      # @return [Hash]
      #
      def send_events(events, opts = {})
        @transporter.write(:POST, '/1/events', { events: events }, opts)
      end
    end

    class UserClient
      # Initializes the Insights userClient
      #
      # @param insights_client [Insights::Client] Insights Client used to make API calls
      # @param user_token [String] user token used to build the client
      #
      def initialize(insights_client, user_token)
        @insights_client = insights_client
        @user_token      = user_token
      end

      # Send a click event to capture clicked items.
      #
      # @param event_name [String] Name of the event.
      # @param index_name [String] Name of the index related to the click.
      # @param object_ids [Array] A list of objectIDs (limited to 20)
      #
      # @return [Hash]
      #
      def clicked_object_ids(event_name, index_name, object_ids, opts = {})
        @insights_client.send_event({
          eventType: 'click',
          eventName: event_name,
          index: index_name,
          userToken: @user_token,
          objectIds: object_ids
        }, opts)
      end

      # Send a click event to capture a query and its clicked items and positions.
      #
      # @param event_name [String] Name of the event.
      # @param index_name [String] Name of the index related to the click.
      # @param object_ids [Array] A list of objectIDs (limited to 20)
      # @param positions [Array] Position of the click in the list of Algolia search results.
      # @param query_id [String] Algolia queryID that can be found in the search response when using clickAnalytics
      #
      # @return [Hash]
      #
      def clicked_object_ids_after_search(event_name, index_name,
        object_ids, positions, query_id, opts = {})
        @insights_client.send_event({
          eventType: 'click',
          eventName: event_name,
          index: index_name,
          userToken: @user_token,
          objectIds: object_ids,
          positions: positions,
          queryId: query_id
        }, opts)
      end

      # Send a click event to capture the filters a user clicks on.
      #
      # @param event_name [String] Name of the event.
      # @param index_name [String] Name of the index related to the click.
      # @param filters [Array] A list of filters (limited to 10)
      #
      # @return [Hash]
      #
      def clicked_filters(event_name, index_name, filters, opts = {})
        @insights_client.send_event({
          eventType: 'click',
          eventName: event_name,
          index: index_name,
          userToken: @user_token,
          filters: filters
        }, opts)
      end

      # Send a conversion event to capture clicked items.
      #
      # @param event_name [String] Name of the event.
      # @param index_name [String] Name of the index related to the click.
      # @param object_ids [Array] A list of objectIDs (limited to 20)
      #
      # @return [Hash]
      #
      def converted_object_ids(event_name, index_name, object_ids, opts = {})
        @insights_client.send_event({
          eventType: 'conversion',
          eventName: event_name,
          index: index_name,
          userToken: @user_token,
          objectIds: object_ids
        }, opts)
      end

      # Send a conversion event to capture a query and its clicked items.
      #
      # @param event_name [String] Name of the event.
      # @param index_name [String] Name of the index related to the click.
      # @param object_ids [Array] A list of objectIDs (limited to 20)
      # @param query_id [String] Algolia queryID, format: [a-z1-9]{32}.
      #
      # @return [Hash]
      #
      def converted_object_ids_after_search(event_name, index_name,
        object_ids, query_id, opts = {})
        @insights_client.send_event({
          eventType: 'conversion',
          eventName: event_name,
          index: index_name,
          userToken: @user_token,
          objectIds: object_ids,
          queryId: query_id
        }, opts)
      end

      # Send a conversion event to capture the filters a user uses when converting.
      #
      # @param event_name [String] Name of the event.
      # @param index_name [String] Name of the index related to the click.
      # @param filters [Array] A list of filters (limited to 10)
      #
      # @return [Hash]
      #
      def converted_filters(event_name, index_name, filters, opts = {})
        @insights_client.send_event({
          eventType: 'conversion',
          eventName: event_name,
          index: index_name,
          userToken: @user_token,
          filters: filters
        }, opts)
      end

      # Send a view event to capture clicked items.
      #
      # @param event_name [String] Name of the event.
      # @param index_name [String] Name of the index related to the click.
      # @param object_ids [Array] A list of objectIDs (limited to 20)
      #
      # @return [Hash]
      #
      def viewed_object_ids(event_name, index_name, object_ids, opts = {})
        @insights_client.send_event({
          eventType: 'view',
          eventName: event_name,
          index: index_name,
          userToken: @user_token,
          objectIds: object_ids
        }, opts)
      end

      # Send a view event to capture the filters a user uses when viewing.
      #
      # @param event_name [String] Name of the event.
      # @param index_name [String] Name of the index related to the click.
      # @param filters [Array] A list of filters (limited to 10)
      #
      # @return [Hash]
      #
      def viewed_filters(event_name, index_name, filters, opts = {})
        @insights_client.send_event({
          eventType: 'view',
          eventName: event_name,
          index: index_name,
          userToken: @user_token,
          filters: filters
        }, opts)
      end
    end
  end
end
