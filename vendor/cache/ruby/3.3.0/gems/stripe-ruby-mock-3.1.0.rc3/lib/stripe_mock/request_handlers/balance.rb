module StripeMock
  module RequestHandlers
    module Balance

      def Balance.included(klass)
        klass.add_handler 'get /v1/balance',                        :get_balance
      end

      def get_balance(route, method_url, params, headers)
        route =~ method_url

        return_balance = Data.mock_balance(account_balance)
        return_balance
      end
    end
  end
end
