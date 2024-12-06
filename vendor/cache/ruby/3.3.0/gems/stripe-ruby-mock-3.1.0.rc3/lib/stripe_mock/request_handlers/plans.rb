module StripeMock
  module RequestHandlers
    module Plans

      def Plans.included(klass)
        klass.add_handler 'post /v1/plans',        :new_plan
        klass.add_handler 'post /v1/plans/(.*)',   :update_plan
        klass.add_handler 'get /v1/plans/(.*)',    :get_plan
        klass.add_handler 'delete /v1/plans/(.*)', :delete_plan
        klass.add_handler 'get /v1/plans',         :list_plans
      end

      def new_plan(route, method_url, params, headers)
        params[:id] ||= new_id('plan')
        validate_create_plan_params(params)
        plans[ params[:id] ] = Data.mock_plan(params)
      end

      def update_plan(route, method_url, params, headers)
        route =~ method_url
        assert_existence :plan, $1, plans[$1]
        plans[$1].merge!(params)
      end

      def get_plan(route, method_url, params, headers)
        route =~ method_url
        assert_existence :plan, $1, plans[$1]
      end

      def delete_plan(route, method_url, params, headers)
        route =~ method_url
        assert_existence :plan, $1, plans.delete($1)
      end

      def list_plans(route, method_url, params, headers)
        limit = params[:limit] ? params[:limit] : 10
        Data.mock_list_object(plans.values.first(limit), params.merge!(limit: limit))
      end

    end
  end
end
