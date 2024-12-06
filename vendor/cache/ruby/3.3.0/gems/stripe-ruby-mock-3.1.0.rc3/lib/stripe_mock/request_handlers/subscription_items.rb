module StripeMock
  module RequestHandlers
    module SubscriptionItems

      def SubscriptionItems.included(klass)
        klass.add_handler 'get /v1/subscription_items', :retrieve_subscription_items
        klass.add_handler 'post /v1/subscription_items/([^/]*)', :update_subscription_item
        klass.add_handler 'post /v1/subscription_items', :create_subscription_items
      end

      def retrieve_subscription_items(route, method_url, params, headers)
        route =~ method_url

        require_param(:subscription) unless params[:subscription]

        Data.mock_list_object(subscriptions_items, params)
      end

      def create_subscription_items(route, method_url, params, headers)
        params[:id] ||= new_id('si')

        require_param(:subscription) unless params[:subscription]
        require_param(:plan) unless params[:plan]

        subscriptions_items[params[:id]] = Data.mock_subscription_item(params.merge(plan: plans[params[:plan]]))
      end

      def update_subscription_item(route, method_url, params, headers)
        route =~ method_url

        subscription_item = assert_existence :subscription_item, $1, subscriptions_items[$1]
        subscription_item.merge!(params.merge(plan: plans[params[:plan]]))
      end
    end
  end
end
