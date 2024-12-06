module StripeMock
  module RequestHandlers
    module Helpers

      def add_external_account_to(type, type_id, params, objects)
        resource = assert_existence type, type_id, objects[type_id]

        source =
          if params[:card]
            card_from_params(params[:card])
          elsif params[:bank_account]
            bank_from_params(params[:bank_account])
          else
            begin
              get_card_by_token(params[:external_account])
            rescue Stripe::InvalidRequestError
              bank_from_params(params[:external_account])
            end
          end
        add_external_account_to_object(type, source, resource)
      end

      def add_external_account_to_object(type, source, object, replace_current=false)
        source[type] = object[:id]
        accounts = object[:external_accounts]

        if replace_current && accounts[:data]
          accounts[:data].delete_if {|source| source[:id] == object[:default_source]}
          object[:default_source] = source[:id]
          accounts[:data] = [source]
        else
          accounts[:total_count] = (accounts[:total_count] || 0) + 1
          (accounts[:data] ||= []) << source
        end
        object[:default_source] = source[:id] if object[:default_source].nil?

        source
      end

      def bank_from_params(attrs_or_token)
        if attrs_or_token.is_a? Hash
          attrs_or_token = generate_bank_token(attrs_or_token)
        end
        get_bank_by_token(attrs_or_token)
      end

    end
  end
end
