module StripeMock
  module RequestHandlers
    module Charges

      def Charges.included(klass)
        klass.add_handler 'post /v1/charges',               :new_charge
        klass.add_handler 'get /v1/charges',                :get_charges
        klass.add_handler 'get /v1/charges/(.*)',           :get_charge
        klass.add_handler 'post /v1/charges/(.*)/capture',  :capture_charge
        klass.add_handler 'post /v1/charges/(.*)/refund',   :refund_charge
        klass.add_handler 'post /v1/charges/(.*)/refunds',  :refund_charge
        klass.add_handler 'post /v1/charges/(.*)',          :update_charge
      end

      def new_charge(route, method_url, params, headers = {})
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key

        if headers && headers[:idempotency_key]
          params[:idempotency_key] = headers[:idempotency_key]
          if charges.any?
            original_charge = charges.values.find { |c| c[:idempotency_key] == headers[:idempotency_key]}
            return charges[original_charge[:id]] if original_charge
          end
        end

        id = new_id('ch')

        if params[:source]
          if params[:source].is_a?(String)
            # if a customer is provided, the card parameter is assumed to be the actual
            # card id, not a token. in this case we'll find the card in the customer
            # object and return that.
            if params[:customer]
              params[:source] = get_card(customers[stripe_account][params[:customer]], params[:source])
            else
              params[:source] = get_card_or_bank_by_token(params[:source])
            end
          elsif params[:source][:id]
            raise Stripe::InvalidRequestError.new("Invalid token id: #{params[:source]}", 'card', http_status: 400)
          end
        elsif params[:customer]
          customer = customers[stripe_account][params[:customer]]
          if customer && customer[:default_source]
            params[:source] = get_card(customer, customer[:default_source])
          end
        end

        ensure_required_params(params)
        bal_trans_params = { amount: params[:amount], source: id, application_fee: params[:application_fee] }

        balance_transaction_id = new_balance_transaction('txn', bal_trans_params)

        charges[id] = Data.mock_charge(
            params.merge :id => id,
            :balance_transaction => balance_transaction_id)

        charge = charges[id].clone
        if params[:expand] == ['balance_transaction']
          charge[:balance_transaction] =
            balance_transactions[balance_transaction_id]
        end

        charge
      end

      def update_charge(route, method_url, params, headers)
        route =~ method_url
        id = $1

        charge = assert_existence :charge, id, charges[id]
        allowed = allowed_params(params)
        disallowed = params.keys - allowed
        if disallowed.count > 0
          raise Stripe::InvalidRequestError.new("Received unknown parameters: #{disallowed.join(', ')}" , '', http_status: 400)
        end

        charges[id] = Util.rmerge(charge, params)
      end

      def get_charges(route, method_url, params, headers)
        params[:offset] ||= 0
        params[:limit] ||= 10

        clone = charges.clone

        if params[:customer]
          clone.delete_if { |k,v| v[:customer] != params[:customer] }
        end

        Data.mock_list_object(clone.values, params)
      end

      def get_charge(route, method_url, params, headers)
        route =~ method_url
        charge_id = $1 || params[:charge]
        charge = assert_existence :charge, charge_id, charges[charge_id]

        charge = charge.clone
        if params[:expand] == ['balance_transaction']
          balance_transaction = balance_transactions[charge[:balance_transaction]]
          charge[:balance_transaction] = balance_transaction
        end

        charge
      end

      def capture_charge(route, method_url, params, headers)
        route =~ method_url
        charge = assert_existence :charge, $1, charges[$1]

        if params[:amount]
          refund = Data.mock_refund(
            :balance_transaction => new_balance_transaction('txn'),
            :id => new_id('re'),
            :amount => charge[:amount] - params[:amount]
          )
          add_refund_to_charge(refund, charge)
        end

        if params[:application_fee]
          charge[:application_fee] = params[:application_fee]
        end

        charge[:captured] = true
        charge
      end

      def refund_charge(route, method_url, params, headers)
        charge = get_charge(route, method_url, params, headers)

        new_refund(
          route,
          method_url,
          params.merge(:charge => charge[:id]),
          headers
        )
      end

      private

      def ensure_required_params(params)
        if params[:amount].nil?
          require_param(:amount)
        elsif params[:currency].nil?
          require_param(:currency)
        elsif non_integer_charge_amount?(params)
          raise Stripe::InvalidRequestError.new("Invalid integer: #{params[:amount]}", 'amount', http_status: 400)
        elsif non_positive_charge_amount?(params)
          raise Stripe::InvalidRequestError.new('Invalid positive integer', 'amount', http_status: 400)
        elsif params[:source].nil? && params[:customer].nil?
          raise Stripe::InvalidRequestError.new('Must provide source or customer.', nil, http_status: nil)
        end
      end

      def non_integer_charge_amount?(params)
        params[:amount] && !params[:amount].is_a?(Integer)
      end

      def non_positive_charge_amount?(params)
        params[:amount] && params[:amount] < 1
      end

      def allowed_params(params)
        allowed = [:description, :metadata, :receipt_email, :fraud_details, :shipping, :destination]

        # This is a workaround for the way the Stripe API sends params even when they aren't modified.
        # Stipe will include those params even when they aren't modified.
        allowed << :fee_details if params.has_key?(:fee_details) && params[:fee_details].nil?
        allowed << :source if params.has_key?(:source) && params[:source].empty?
        if params.has_key?(:refunds) && (params[:refunds].empty? ||
           params[:refunds].has_key?(:data) && params[:refunds][:data].nil?)
          allowed << :refunds
        end

        allowed
      end
    end
  end
end
