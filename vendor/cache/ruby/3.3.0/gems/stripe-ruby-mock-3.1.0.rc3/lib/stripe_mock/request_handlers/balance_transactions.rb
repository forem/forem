module StripeMock
  module RequestHandlers
    module BalanceTransactions

      def BalanceTransactions.included(klass)
        klass.add_handler 'get /v1/balance_transactions/(.*)',  :get_balance_transaction
        klass.add_handler 'get /v1/balance_transactions',       :list_balance_transactions
      end

      def get_balance_transaction(route, method_url, params, headers)
        route =~ method_url
        assert_existence :balance_transaction, $1, hide_additional_attributes(balance_transactions[$1])
      end

      def list_balance_transactions(route, method_url, params, headers)
        values = balance_transactions.values
        if params.has_key?(:transfer)
          # If transfer supplied as params, need to filter the btxns returned to only include those with the specified transfer id
          values = values.select{|btxn| btxn[:transfer] == params[:transfer]}
        end
        Data.mock_list_object(values.map{|btxn| hide_additional_attributes(btxn)}, params)
      end

      private

      def hide_additional_attributes(btxn)
        # For automatic Stripe transfers, the transfer attribute on balance_transaction stores the transfer which
        # included this balance_transaction.  However, it is not exposed as a field returned on a balance_transaction.
        # Therefore, need to not show this attribute if it exists.
        if !btxn.nil?
          btxn.reject{|k,v| k == :transfer }
        end
      end

    end
  end
end
