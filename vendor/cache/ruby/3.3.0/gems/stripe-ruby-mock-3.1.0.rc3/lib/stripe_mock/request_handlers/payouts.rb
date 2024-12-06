module StripeMock
  module RequestHandlers
    module Payouts

      def Payouts.included(klass)
        klass.add_handler 'post /v1/payouts',            :new_payout
        klass.add_handler 'get /v1/payouts',             :list_payouts
        klass.add_handler 'get /v1/payouts/(.*)',        :get_payout
      end

      def new_payout(route, method_url, params, headers)
        id = new_id('po')

        unless params[:amount].is_a?(Integer) || (params[:amount].is_a?(String) && /^\d+$/.match(params[:amount]))
          raise Stripe::InvalidRequestError.new("Invalid integer: #{params[:amount]}", 'amount', http_status: 400)
        end

        payouts[id] = Data.mock_payout(params.merge :id => id)
      end

      def list_payouts(route, method_url, params, headers)
        Data.mock_list_object(payouts.clone.values, params)
      end

      def get_payout(route, method_url, params, headers)
        route =~ method_url
        assert_existence :payout, $1, payouts[$1]
        payouts[$1] ||= Data.mock_payout(:id => $1)
      end
    end
  end
end
