module StripeMock
  module RequestHandlers
    module Events

      def Events.included(klass)
        klass.add_handler 'get /v1/events/(.*)', :retrieve_event
        klass.add_handler 'get /v1/events',      :list_events 
      end

      def retrieve_event(route, method_url, params, headers)
        route =~ method_url
        assert_existence :event, $1, events[$1]
      end

      def list_events(route, method_url, params, headers)
        Data.mock_list_object(events.values, params)
      end
      
    end
  end
end
