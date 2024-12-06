module StripeMock
  module RequestHandlers
    module Cards

      def Cards.included(klass)
        klass.add_handler 'get /v1/recipients/(.*)/cards', :retrieve_recipient_cards
        klass.add_handler 'get /v1/recipients/(.*)/cards/(.*)', :retrieve_recipient_card
        klass.add_handler 'post /v1/recipients/(.*)/cards', :create_recipient_card
        klass.add_handler 'delete /v1/recipients/(.*)/cards/(.*)', :delete_recipient_card
      end

      def create_recipient_card(route, method_url, params, headers)
        route =~ method_url
        add_card_to(:recipient, $1, params, recipients)
      end

      def retrieve_recipient_cards(route, method_url, params, headers)
        route =~ method_url
        retrieve_object_cards(:recipient, $1, recipients)
      end

      def retrieve_recipient_card(route, method_url, params, headers)
        route =~ method_url
        recipient = assert_existence :recipient, $1, recipients[$1]

        assert_existence :card, $2, get_card(recipient, $2, "Recipient")
      end

      def delete_recipient_card(route, method_url, params, headers)
        route =~ method_url
        delete_card_from(:recipient, $1, $2, recipients)
      end
    end
  end
end
