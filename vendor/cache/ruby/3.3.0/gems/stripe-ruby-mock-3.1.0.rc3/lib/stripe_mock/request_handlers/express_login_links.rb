module StripeMock
  module RequestHandlers
    module ExpressLoginLinks

      def ExpressLoginLinks.included(klass)
        klass.add_handler 'post /v1/accounts/(.*)/login_links', :new_account_login_link
      end

      def new_account_login_link(route, method_url, params, headers)
        route =~ method_url
        Data.mock_express_login_link(params)
      end
    end
  end
end
