module StripeMock
  module RequestHandlers
    module AccountLinks

      def AccountLinks.included(klass)
        klass.add_handler 'post /v1/account_links',      :new_account_link
      end

      def new_account_link(route, method_url, params, headers)
        route =~ method_url
        Data.mock_account_link(params)
      end
    end
  end
end
