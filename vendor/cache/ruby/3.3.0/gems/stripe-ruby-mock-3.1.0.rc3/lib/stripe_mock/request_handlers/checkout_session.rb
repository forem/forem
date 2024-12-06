module StripeMock
  module RequestHandlers
    module Checkout
      module Session
        def Session.included(klass)
          klass.add_handler 'get /v1/checkout/sessions/(.*)', :get_checkout_session
        end

        def get_checkout_session(route, method_url, params, headers)
          route =~ method_url
          checkout_session = assert_existence :checkout_session, $1, checkout_sessions[$1]

          checkout_session = checkout_session.clone
          if params[:expand]&.include?('setup_intent') && checkout_session[:setup_intent]
            checkout_session[:setup_intent] = setup_intents[checkout_session[:setup_intent]]
          end
          checkout_session
        end
      end
    end
  end
end
