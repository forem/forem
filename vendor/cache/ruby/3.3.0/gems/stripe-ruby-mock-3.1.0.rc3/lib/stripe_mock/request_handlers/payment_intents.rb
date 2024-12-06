module StripeMock
  module RequestHandlers
    module PaymentIntents
      ALLOWED_PARAMS = [:description, :metadata, :receipt_email, :shipping, :destination, :payment_method, :payment_method_types, :setup_future_usage, :transfer_data, :amount, :currency]

      def PaymentIntents.included(klass)
        klass.add_handler 'post /v1/payment_intents',               :new_payment_intent
        klass.add_handler 'get /v1/payment_intents',                :get_payment_intents
        klass.add_handler 'get /v1/payment_intents/(.*)',           :get_payment_intent
        klass.add_handler 'post /v1/payment_intents/(.*)/confirm',  :confirm_payment_intent
        klass.add_handler 'post /v1/payment_intents/(.*)/capture',  :capture_payment_intent
        klass.add_handler 'post /v1/payment_intents/(.*)/cancel',   :cancel_payment_intent
        klass.add_handler 'post /v1/payment_intents/(.*)',          :update_payment_intent
      end

      def new_payment_intent(route, method_url, params, headers)
        id = new_id('pi')

        ensure_payment_intent_required_params(params)
        status = case params[:amount]
        when 3184 then 'requires_action'
        when 3178 then 'requires_payment_method'
        when 3055 then 'requires_capture'
        else
          'succeeded'
        end
        last_payment_error = params[:amount] == 3178 ? last_payment_error_generator(code: 'card_declined', decline_code: 'insufficient_funds', message: 'Not enough funds.') : nil
        payment_intents[id] = Data.mock_payment_intent(
          params.merge(
            id: id,
            status: status,
            last_payment_error: last_payment_error
          )
        )

        if params[:confirm] && status == 'succeeded'
          payment_intents[id] = succeeded_payment_intent(payment_intents[id])
        end

        payment_intents[id].clone
      end

      def update_payment_intent(route, method_url, params, headers)
        route =~ method_url
        id = $1

        payment_intent = assert_existence :payment_intent, id, payment_intents[id]
        payment_intents[id] = Util.rmerge(payment_intent, params.select{ |k,v| ALLOWED_PARAMS.include?(k)})
      end

      def get_payment_intents(route, method_url, params, headers)
        params[:offset] ||= 0
        params[:limit] ||= 10

        clone = payment_intents.clone

        if params[:customer]
          clone.delete_if { |k,v| v[:customer] != params[:customer] }
        end

        Data.mock_list_object(clone.values, params)
      end

      def get_payment_intent(route, method_url, params, headers)
        route =~ method_url
        payment_intent_id = $1 || params[:payment_intent]
        payment_intent = assert_existence :payment_intent, payment_intent_id, payment_intents[payment_intent_id]

        payment_intent = payment_intent.clone
        payment_intent
      end

      def capture_payment_intent(route, method_url, params, headers)
        route =~ method_url
        payment_intent = assert_existence :payment_intent, $1, payment_intents[$1]

        succeeded_payment_intent(payment_intent)
      end

      def confirm_payment_intent(route, method_url, params, headers)
        route =~ method_url
        payment_intent = assert_existence :payment_intent, $1, payment_intents[$1]

        succeeded_payment_intent(payment_intent)
      end

      def cancel_payment_intent(route, method_url, params, headers)
        route =~ method_url
        payment_intent = assert_existence :payment_intent, $1, payment_intents[$1]

        payment_intent[:status] = 'canceled'
        payment_intent
      end

      private

      def ensure_payment_intent_required_params(params)
        if params[:amount].nil?
          require_param(:amount)
        elsif params[:currency].nil?
          require_param(:currency)
        elsif non_integer_charge_amount?(params)
          raise Stripe::InvalidRequestError.new("Invalid integer: #{params[:amount]}", 'amount', http_status: 400)
        elsif non_positive_charge_amount?(params)
          raise Stripe::InvalidRequestError.new('Invalid positive integer', 'amount', http_status: 400)
        end
      end

      def non_integer_charge_amount?(params)
        params[:amount] && !params[:amount].is_a?(Integer)
      end

      def non_positive_charge_amount?(params)
        params[:amount] && params[:amount] < 1
      end

      def last_payment_error_generator(code: nil, message: nil, decline_code: nil)
        {
          code: code,
          doc_url: "https://stripe.com/docs/error-codes/payment-intent-authentication-failure",
          message: message,
          decline_code: decline_code,
          payment_method: {
            id: "pm_1EwXFA2eZvKYlo2C0tlY091l",
            object: "payment_method",
            billing_details: {
              address: {
                city: nil,
                country: nil,
                line1: nil,
                line2: nil,
                postal_code: nil,
                state: nil
              },
              email: nil,
              name: "seller_08072019090000",
              phone: nil
            },
            card: {
              brand: "visa",
              checks: {
                address_line1_check: nil,
                address_postal_code_check: nil,
                cvc_check: "unchecked"
              },
              country: "US",
              exp_month: 12,
              exp_year: 2021,
              fingerprint: "LQBhEmJnItuj3mxf",
              funding: "credit",
              generated_from: nil,
              last4: "1629",
              three_d_secure_usage: {
                supported: true
              },
              wallet: nil
            },
            created: 1563208900,
            customer: nil,
            livemode: false,
            metadata: {},
            type: "card"
          },
          type: "invalid_request_error"
        }
      end

      def succeeded_payment_intent(payment_intent)
        payment_intent[:status] = 'succeeded'
        btxn = new_balance_transaction('txn', { source: payment_intent[:id] })

        payment_intent[:charges][:data] << Data.mock_charge(
          balance_transaction: btxn,
          amount: payment_intent[:amount],
          currency: payment_intent[:currency]
        )

        payment_intent
      end
    end
  end
end
