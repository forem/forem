module StripeMock
  module RequestHandlers
    module PaymentMethods
      ALLOWED_PARAMS = [:customer, :type]

      def PaymentMethods.included(klass)
        klass.add_handler 'post /v1/payment_methods',             :new_payment_method
        klass.add_handler 'get /v1/payment_methods/(.*)',         :get_payment_method
        klass.add_handler 'get /v1/payment_methods',              :get_payment_methods
        klass.add_handler 'post /v1/payment_methods/(.*)/attach', :attach_payment_method
        klass.add_handler 'post /v1/payment_methods/(.*)/detach', :detach_payment_method
        klass.add_handler 'post /v1/payment_methods/(.*)',        :update_payment_method
      end

      # post /v1/payment_methods
      def new_payment_method(route, method_url, params, headers)
        id = new_id('pm')

        ensure_payment_method_required_params(params)

        payment_methods[id] = Data.mock_payment_method(
          params.merge(
            id: id
          )
        )

        payment_methods[id].clone
      end

      #
      # params: {:type=>"card", :customer=>"test_cus_3"}
      #
      # get /v1/payment_methods/:id
      def get_payment_method(route, method_url, params, headers)
        id = method_url.match(route)[1] || params[:payment_method]
        payment_method = assert_existence :payment_method, id, payment_methods[id]

        payment_method.clone
      end

      # get /v1/payment_methods
      def get_payment_methods(route, method_url, params, headers)
        params[:offset] ||= 0
        params[:limit] ||= 10

        clone = payment_methods.clone

        if params[:customer]
          clone.delete_if { |_k, v| v[:customer] != params[:customer] }
        end

        Data.mock_list_object(clone.values, params)
      end

      # post /v1/payment_methods/:id/attach
      def attach_payment_method(route, method_url, params, headers)
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        allowed_params = [:customer]

        id = method_url.match(route)[1]

        assert_existence :customer, params[:customer], customers[stripe_account][params[:customer]]

        payment_method = assert_existence :payment_method, id, payment_methods[id]
        payment_methods[id] = Util.rmerge(payment_method, params.select { |k, _v| allowed_params.include?(k) })
        payment_methods[id].clone
      end

      # post /v1/payment_methods/:id/detach
      def detach_payment_method(route, method_url, params, headers)
        id = method_url.match(route)[1]

        payment_method = assert_existence :payment_method, id, payment_methods[id]
        payment_method[:customer] = nil

        payment_method.clone
      end

      # post /v1/payment_methods/:id
      def update_payment_method(route, method_url, params, headers)
        allowed_params = [:billing_details, :card, :ideal, :sepa_debit, :metadata]

        id = method_url.match(route)[1]

        payment_method = assert_existence :payment_method, id, payment_methods[id]

        if payment_method[:customer].nil?
          raise Stripe::InvalidRequestError.new(
            'You must save this PaymentMethod to a customer before you can update it.',
            nil,
            http_status: 400
          )
        end

        payment_methods[id] =
          Util.rmerge(payment_method, params.select { |k, _v| allowed_params.include?(k)} )

        payment_methods[id].clone
      end

      private

      def ensure_payment_method_required_params(params)
        require_param(:type) if params[:type].nil?

        if invalid_type?(params[:type])
          raise Stripe::InvalidRequestError.new(
            'Invalid type: must be one of card, ideal or sepa_debit',
            nil,
            http_status: 400
          )
        end
      end

      def invalid_type?(type)
        !%w(card ideal sepa_debit).include?(type)
      end
    end
  end
end
