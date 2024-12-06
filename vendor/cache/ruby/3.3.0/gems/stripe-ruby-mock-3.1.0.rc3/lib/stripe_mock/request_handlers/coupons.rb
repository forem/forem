module StripeMock
  module RequestHandlers
    module Coupons

      def Coupons.included(klass)
        klass.add_handler 'post /v1/coupons',        :new_coupon
        klass.add_handler 'get /v1/coupons/(.*)',    :get_coupon
        klass.add_handler 'delete /v1/coupons/(.*)', :delete_coupon
        klass.add_handler 'get /v1/coupons',         :list_coupons
      end

      def new_coupon(route, method_url, params, headers)
        params[:id] ||= new_id('coupon')
        raise Stripe::InvalidRequestError.new('Missing required param: duration', 'coupon', http_status: 400) unless params[:duration]
        raise Stripe::InvalidRequestError.new('You must pass currency when passing amount_off', 'coupon', http_status: 400) if params[:amount_off] && !params[:currency]
        coupons[ params[:id] ] = Data.mock_coupon({amount_off: nil, percent_off:nil}.merge(params))
      end

      def get_coupon(route, method_url, params, headers)
        route =~ method_url
        assert_existence :coupon, $1, coupons[$1]
      end

      def delete_coupon(route, method_url, params, headers)
        route =~ method_url
        assert_existence :coupon, $1, coupons.delete($1)
      end

      def list_coupons(route, method_url, params, headers)
        Data.mock_list_object(coupons.values, params)
      end

    end
  end
end
