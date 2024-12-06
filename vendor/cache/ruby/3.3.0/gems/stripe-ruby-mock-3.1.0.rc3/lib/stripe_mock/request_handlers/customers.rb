module StripeMock
  module RequestHandlers
    module Customers

      def Customers.included(klass)
        klass.add_handler 'post /v1/customers',                     :new_customer
        klass.add_handler 'post /v1/customers/([^/]*)',             :update_customer
        klass.add_handler 'get /v1/customers/([^/]*)',              :get_customer
        klass.add_handler 'delete /v1/customers/([^/]*)',           :delete_customer
        klass.add_handler 'get /v1/customers',                      :list_customers
        klass.add_handler 'delete /v1/customers/([^/]*)/discount',  :delete_customer_discount
      end

      def new_customer(route, method_url, params, headers)
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        params[:id] ||= new_id('cus')
        sources = []

        if params[:source]
          new_card =
            if params[:source].is_a?(Hash)
              unless params[:source][:object] && params[:source][:number] && params[:source][:exp_month] && params[:source][:exp_year]
                raise Stripe::InvalidRequestError.new('You must supply a valid card', nil, http_status: 400)
              end
              card_from_params(params[:source])
            else
              get_card_or_bank_by_token(params.delete(:source))
            end
          sources << new_card
          params[:default_source] = sources.first[:id]
        end

        customers[stripe_account] ||= {}
        customers[stripe_account][params[:id]] = Data.mock_customer(sources, params)

        if params[:plan]
          plan_id = params[:plan].to_s
          plan = assert_existence :plan, plan_id, plans[plan_id]

          if params[:default_source].nil? && params[:trial_end].nil? && plan[:trial_period_days].nil? && plan[:amount] != 0
            raise Stripe::InvalidRequestError.new('You must supply a valid card', nil, http_status: 400)
          end

          subscription = Data.mock_subscription({ id: new_id('su') })
          subscription = resolve_subscription_changes(subscription, [plan], customers[stripe_account][params[:id]], params)
          add_subscription_to_customer(customers[stripe_account][params[:id]], subscription)
          subscriptions[subscription[:id]] = subscription
        elsif params[:trial_end]
          raise Stripe::InvalidRequestError.new('Received unknown parameter: trial_end', nil, http_status: 400)
        end

        if params[:coupon]
          coupon = coupons[params[:coupon]]
          assert_existence :coupon, params[:coupon], coupon
          add_coupon_to_object(customers[stripe_account][params[:id]], coupon)
        end

        customers[stripe_account][params[:id]]
      end

      def update_customer(route, method_url, params, headers)
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        route =~ method_url
        cus = assert_existence :customer, $1, customers[stripe_account][$1]

        # get existing and pending metadata
        metadata = cus.delete(:metadata) || {}
        metadata_updates = params.delete(:metadata) || {}

        # Delete those params if their value is nil. Workaround of the problematic way Stripe serialize objects
        params.delete(:sources) if params[:sources] && params[:sources][:data].nil?
        params.delete(:subscriptions) if params[:subscriptions] && params[:subscriptions][:data].nil?
        # Delete those params if their values aren't valid. Workaround of the problematic way Stripe serialize objects
        if params[:sources] && !params[:sources][:data].nil?
          params.delete(:sources) unless params[:sources][:data].any?{ |v| !!v[:type]}
        end
        if params[:subscriptions] && !params[:subscriptions][:data].nil?
          params.delete(:subscriptions) unless params[:subscriptions][:data].any?{ |v| !!v[:type]}
        end
        cus.merge!(params)
        cus[:metadata] = {**metadata, **metadata_updates}

        if params[:source]
          if params[:source].is_a?(String)
            new_card = get_card_or_bank_by_token(params.delete(:source))
          elsif params[:source].is_a?(Stripe::Token)
            new_card = get_card_or_bank_by_token(params[:source][:id])
          elsif params[:source].is_a?(Hash)
            unless params[:source][:object] && params[:source][:number] && params[:source][:exp_month] && params[:source][:exp_year]
              raise Stripe::InvalidRequestError.new('You must supply a valid card', nil, http_status: 400)
            end
            new_card = card_from_params(params.delete(:source))
          end
          add_card_to_object(:customer, new_card, cus, true)
          cus[:default_source] = new_card[:id]
        end

        if params[:coupon]
          if params[:coupon] == ''
            delete_coupon_from_object(cus)
          else
            coupon = coupons[params[:coupon]]
            assert_existence :coupon, params[:coupon], coupon

            add_coupon_to_object(cus, coupon)
          end
        end

        cus
      end

      def delete_customer(route, method_url, params, headers)
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        route =~ method_url
        assert_existence :customer, $1, customers[stripe_account][$1]

        customers[stripe_account][$1] = {
          id: customers[stripe_account][$1][:id],
          deleted: true
        }
      end

      def get_customer(route, method_url, params, headers)
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        route =~ method_url
        customer = assert_existence :customer, $1, customers[stripe_account][$1]

        customer = customer.clone
        if params[:expand] == ['default_source'] && customer[:sources][:data]
          customer[:default_source] = customer[:sources][:data].detect do |source|
            source[:id] == customer[:default_source]
          end
        end

        customer
      end

      def list_customers(route, method_url, params, headers)
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        Data.mock_list_object(customers[stripe_account]&.values, params)
      end

      def delete_customer_discount(route, method_url, params, headers)
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        route =~ method_url
        cus = assert_existence :customer, $1, customers[stripe_account][$1]

        cus[:discount] = nil

        cus
      end
    end
  end
end
