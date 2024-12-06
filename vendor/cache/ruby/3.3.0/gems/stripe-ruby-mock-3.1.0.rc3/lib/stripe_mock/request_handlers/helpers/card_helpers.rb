module StripeMock
  module RequestHandlers
    module Helpers

      def get_card(object, card_id, class_name='Customer')
        cards = object[:cards] || object[:sources] || object[:external_accounts]
        card = cards[:data].find{|cc| cc[:id] == card_id }
        if card.nil?
          if class_name == 'Recipient'
            msg = "#{class_name} #{object[:id]} does not have a card with ID #{card_id}"
            raise Stripe::InvalidRequestError.new(msg, 'card', http_status: 404)
          else
            msg = "There is no source with ID #{card_id}"
            raise Stripe::InvalidRequestError.new(msg, 'id', http_status: 404)
          end
        end
        card
      end

      def add_source_to_object(type, source, object, replace_current=false)
        source[type] = object[:id]
        sources = object[:sources]

        if replace_current && sources[:data]
          sources[:data].delete_if {|source| source[:id] == object[:default_source]}
          object[:default_source] = source[:id]
          sources[:data] = [source]
        else
          sources[:total_count] = (sources[:total_count] || 0) + 1
          (sources[:data] ||= []) << source
        end
        object[:default_source] = source[:id] if object[:default_source].nil?

        source
      end

      def add_card_to_object(type, card, object, replace_current=false)
        card[type] = object[:id]
        cards_or_sources = object[:cards] || object[:sources] || object[:external_accounts]

        is_customer = object.has_key?(:sources)

        if replace_current && cards_or_sources[:data]
          cards_or_sources[:data].delete_if {|card| card[:id] == object[:default_card]}
          object[:default_card]   = card[:id] unless is_customer
          object[:default_source] = card[:id] if is_customer
          cards_or_sources[:data] = [card]
        else
          cards_or_sources[:total_count] = (cards_or_sources[:total_count] || 0) + 1
          (cards_or_sources[:data] ||= []) << card
        end

        object[:default_card]   = card[:id] if !is_customer && object[:default_card].nil?
        object[:default_source] = card[:id] if is_customer  && object[:default_source].nil?

        card
      end

      def retrieve_object_cards(type, type_id, objects)
        resource = assert_existence type, type_id, objects[type_id]
        cards = resource[:cards] || resource[:sources] || resource[:external_accounts]

        Data.mock_list_object(cards[:data])
      end

      def delete_card_from(type, type_id, card_id, objects)
        resource = assert_existence type, type_id, objects[type_id]

        assert_existence :card, card_id, get_card(resource, card_id)

        card = { id: card_id, deleted: true }
        cards_or_sources = resource[:cards] || resource[:sources] || resource[:external_accounts]
        cards_or_sources[:data].reject!{|cc|
          cc[:id] == card[:id]
        }

        is_customer = resource.has_key?(:sources)
        new_default = cards_or_sources[:data].count > 0 ? cards_or_sources[:data].first[:id] : nil
        resource[:default_card]   = new_default unless is_customer
        resource[:sources][:total_count] = cards_or_sources[:data].count if is_customer
        resource[:default_source] = new_default if is_customer
        card
      end

      def add_source_to(type, type_id, params, objects)
        resource = assert_existence type, type_id, objects[type_id]

        source =
          if params[:card]
            card_from_params(params[:card])
          elsif params[:bank_account]
            get_bank_by_token(params[:bank_account])
          else
            begin
              get_card_by_token(params[:source])
            rescue Stripe::InvalidRequestError
              get_bank_by_token(params[:source])
            end
          end
        source[:metadata].merge!(params[:metadata]) if params[:metadata]
        add_source_to_object(type, source, resource)
      end

      def add_card_to(type, type_id, params, objects)
        resource = assert_existence type, type_id, objects[type_id]

        card = card_from_params(params[:card] || params[:source] || params[:external_accounts])
        add_card_to_object(type, card, resource)
      end

      def validate_card(card)
        [:exp_month, :exp_year].each do |field|
          card[field] = card[field].to_i
        end
        card
      end

      def card_from_params(attrs_or_token)
        if attrs_or_token.is_a? Hash
          attrs_or_token = generate_card_token(attrs_or_token)
        end
        card = get_card_by_token(attrs_or_token)
        validate_card(card)
      end
    end
  end
end
