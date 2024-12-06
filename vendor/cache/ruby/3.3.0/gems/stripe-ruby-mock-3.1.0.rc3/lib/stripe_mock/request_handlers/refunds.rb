module StripeMock
  module RequestHandlers
    module Refunds

      def Refunds.included(klass)
        klass.add_handler 'post /v1/refunds',               :new_refund
        klass.add_handler 'get /v1/refunds',                :get_refunds
        klass.add_handler 'get /v1/refunds/(.*)',           :get_refund
        klass.add_handler 'post /v1/refunds/(.*)',          :update_refund
      end

      def new_refund(route, method_url, params, headers)
        if headers && headers[:idempotency_key]
          params[:idempotency_key] = headers[:idempotency_key]
          if refunds.any?
            original_refund = refunds.values.find { |c| c[:idempotency_key] == headers[:idempotency_key]}
            return refunds[original_refund[:id]] if original_refund
          end
        end

        charge = assert_existence :charge, params[:charge], charges[params[:charge]]
        params[:amount] ||= charge[:amount]
        id = new_id('re')
        bal_trans_params = {
          amount: params[:amount] * -1,
          source: id,
          type: 'refund'
        }
        balance_transaction_id = new_balance_transaction('txn', bal_trans_params)
        refund = Data.mock_refund params.merge(
          :balance_transaction => balance_transaction_id,
          :id => id,
          :charge => charge[:id],
        )
        add_refund_to_charge(refund, charge)
        refunds[id] = refund

        if params[:expand] == ['balance_transaction']
          refunds[id][:balance_transaction] =
            balance_transactions[balance_transaction_id]
        end
        refund
      end

      def update_refund(route, method_url, params, headers)
        route =~ method_url
        id = $1

        refund = assert_existence :refund, id, refunds[id]
        allowed = allowed_refund_params(params)
        disallowed = params.keys - allowed
        if disallowed.count > 0
          raise Stripe::InvalidRequestError.new("Received unknown parameters: #{disallowed.join(', ')}" , '', http_status: 400)
        end

        refunds[id] = Util.rmerge(refund, params)
      end

      def get_refunds(route, method_url, params, headers)
        params[:offset] ||= 0
        params[:limit] ||= 10

        clone = refunds.clone

        Data.mock_list_object(clone.values, params)
      end

      def get_refund(route, method_url, params, headers)
        route =~ method_url
        refund_id = $1 || params[:refund]
        assert_existence :refund, refund_id, refunds[refund_id]
      end

      private

      def ensure_refund_required_params(params)
        if non_integer_charge_amount?(params)
          raise Stripe::InvalidRequestError.new("Invalid integer: #{params[:amount]}", 'amount', http_status: 400)
        elsif non_positive_charge_amount?(params)
          raise Stripe::InvalidRequestError.new('Invalid positive integer', 'amount', http_status: 400)
        elsif params[:charge].nil?
          raise Stripe::InvalidRequestError.new('Must provide the identifier of the charge to refund.', nil)
        end
      end

      def allowed_refund_params(params)
        [:metadata]
      end
    end
  end
end
