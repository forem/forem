require_relative "config"
require_relative "manages_transactions"
require_relative "initializer_hooks"

module CypressRails
  class ResetsState
    def initialize
      @manages_transactions = ManagesTransactions.instance
      @initializer_hooks = InitializerHooks.instance
    end

    def call(transactional_server:)
      if transactional_server
        @manages_transactions.rollback_transaction
        @manages_transactions.begin_transaction
      end
      @initializer_hooks.run(:after_state_reset)
    end
  end
end
