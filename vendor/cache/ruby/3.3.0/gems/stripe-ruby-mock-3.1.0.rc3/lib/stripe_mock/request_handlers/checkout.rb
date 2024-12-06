module StripeMock
  module RequestHandlers
    module Checkout
      def Checkout.included(klass)
        klass.add_handler 'post /v1/checkout/sessions', :new_session
      end

      def new_session(route, method_url, params, headers)
        params[:id] ||= new_id('cs')

        checkout_sessions[params[:id]] = Data.mock_checkout_session(params)
      end
    end
  end
end