module StripeMock
  module RequestHandlers
    module Recipients

      def Recipients.included(klass)
        klass.add_handler 'post /v1/recipients',            :new_recipient
        klass.add_handler 'post /v1/recipients/(.*)',       :update_recipient
        klass.add_handler 'get /v1/recipients/(.*)',        :get_recipient
      end

      def new_recipient(route, method_url, params, headers)
        params[:id] ||= new_id('rp')
        cards = []

        if params[:name].nil?
          raise StripeMock::StripeMockError.new("Missing required parameter name for recipients.")
        end

        if params[:type].nil?
          raise StripeMock::StripeMockError.new("Missing required parameter type for recipients.")
        end

        unless %w(individual corporation).include?(params[:type])
          raise StripeMock::StripeMockError.new("Type must be either individual or corporation..")
        end

        if params[:bank_account]
          params[:active_account] = get_bank_by_token(params.delete(:bank_account))
        end

        if params[:card]
          cards << get_card_by_token(params.delete(:card))
          params[:default_card] = cards.first[:id]
        end

        recipients[ params[:id] ] = Data.mock_recipient(cards, params)
        recipients[ params[:id] ]
      end

      def update_recipient(route, method_url, params, headers)
        route =~ method_url
        recipient = assert_existence :recipient, $1, recipients[$1]
        recipient.merge!(params)

        if params[:card]
          new_card = get_card_by_token(params.delete(:card))
          add_card_to_object(:recipient, new_card, recipient, true)
          recipient[:default_card] = new_card[:id]
        end

        recipient
      end

      def get_recipient(route, method_url, params, headers)
        route =~ method_url
        assert_existence :recipient, $1, recipients[$1]
      end
    end
  end
end
