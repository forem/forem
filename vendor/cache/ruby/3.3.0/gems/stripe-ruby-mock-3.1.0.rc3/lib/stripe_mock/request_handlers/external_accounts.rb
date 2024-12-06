module StripeMock
  module RequestHandlers
    module ExternalAccounts

      def ExternalAccounts.included(klass)
        klass.add_handler 'get /v1/accounts/(.*)/external_accounts', :retrieve_external_accounts
        klass.add_handler 'post /v1/accounts/(.*)/external_accounts', :create_external_account
        klass.add_handler 'post /v1/accounts/(.*)/external_accounts/(.*)/verify', :verify_external_account
        klass.add_handler 'get /v1/accounts/(.*)/external_accounts/(.*)', :retrieve_external_account
        klass.add_handler 'delete /v1/accounts/(.*)/external_accounts/(.*)', :delete_external_account
        klass.add_handler 'post /v1/accounts/(.*)/external_accounts/(.*)', :update_external_account
      end

      def create_external_account(route, method_url, params, headers)
        route =~ method_url
        add_external_account_to(:account, $1, params, accounts)
      end

      def retrieve_external_accounts(route, method_url, params, headers)
        route =~ method_url
        retrieve_object_cards(:account, $1, accounts)
      end

      def retrieve_external_account(route, method_url, params, headers)
        route =~ method_url
        account = assert_existence :account, $1, accounts[$1]

        assert_existence :card, $2, get_card(account, $2)
      end

      def delete_external_account(route, method_url, params, headers)
        route =~ method_url
        delete_card_from(:account, $1, $2, accounts)
      end

      def update_external_account(route, method_url, params, headers)
        route =~ method_url
        account = assert_existence :account, $1, accounts[$1]

        card = assert_existence :card, $2, get_card(account, $2)
        card.merge!(params)
        card
      end

      def verify_external_account(route, method_url, params, headers)
        route =~ method_url
        account = assert_existence :account, $1, accounts[$1]

        external_account = assert_existence :bank_account, $2, verify_bank_account(account, $2)
        external_account
      end

    end
  end
end
