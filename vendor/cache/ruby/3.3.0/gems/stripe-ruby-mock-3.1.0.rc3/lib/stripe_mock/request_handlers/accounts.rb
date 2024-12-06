module StripeMock
  module RequestHandlers
    module Accounts
      VALID_START_YEAR = 2009

      def Accounts.included(klass)
        klass.add_handler 'post /v1/accounts',      :new_account
        klass.add_handler 'get /v1/account',        :get_account
        klass.add_handler 'get /v1/accounts/(.*)',  :get_account
        klass.add_handler 'post /v1/accounts/(.*)', :update_account
        klass.add_handler 'get /v1/accounts',       :list_accounts
        klass.add_handler 'post /oauth/deauthorize',:deauthorize
      end

      def new_account(route, method_url, params, headers)
        params[:id] ||= new_id('acct')
        route =~ method_url
        accounts[params[:id]] ||= Data.mock_account(params)
      end

      def get_account(route, method_url, params, headers)
        route =~ method_url
        init_account
        id = $1 || accounts.keys[0]
        assert_existence :account, id, accounts[id]
      end

      def update_account(route, method_url, params, headers)
        route =~ method_url
        account = assert_existence :account, $1, accounts[$1]
        account.merge!(params)
        if blank_value?(params[:tos_acceptance], :date)
          raise Stripe::InvalidRequestError.new("Invalid integer: ", "tos_acceptance[date]", http_status: 400)
        elsif params[:tos_acceptance] && params[:tos_acceptance][:date]
          validate_acceptance_date(params[:tos_acceptance][:date])
        end
        account
      end

      def list_accounts(route, method_url, params, headers)
        init_account
        Data.mock_list_object(accounts.values, params)
      end

      def deauthorize(route, method_url, params, headers)
        init_account
        route =~ method_url
        Stripe::StripeObject.construct_from(:stripe_user_id => params[:stripe_user_id])
      end

      private

      def init_account
        if accounts == {}
          acc = Data.mock_account
          accounts[acc[:id]] = acc
        end
      end

      # Checks if setting a blank value
      #
      # returns true if the key is included in the hash
      # and its value is empty or nil
      def blank_value?(hash, key)
        if hash.key?(key)
          value = hash[key]
          return true if value.nil? || "" == value
        end
        false
      end

      def validate_acceptance_date(unix_date)
        unix_now = Time.now.strftime("%s").to_i
        formatted_date = Time.at(unix_date)

        return if formatted_date.year >= VALID_START_YEAR && unix_now >= unix_date

        raise Stripe::InvalidRequestError.new(
          "ToS acceptance date is not valid. Dates are expected to be integers, measured in seconds, not in the future, and after 2009",
          "tos_acceptance[date]", 
          http_status: 400
        )
      end
    end
  end
end
