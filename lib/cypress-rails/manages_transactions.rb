require "cypress-rails/manages_transactions"

# Rails 8 removed ConnectionPool#connection and #lock_thread=, which
# cypress-rails 0.7 still uses to wrap the test server in a transaction
# (testdouble/cypress-rails#165 is unmerged). Replaces the connection-based
# strategy with the pool pinning Rails 8's own transactional fixtures use.
module CypressRails
  class ManagesTransactions
    def begin_transaction
      setup_shared_connection_pool

      @connection_pools = ActiveRecord::Base.connection_handler.connection_pool_list(:writing)
      @connection_pools.each do |pool|
        pool.pin_connection!(true)
        pool.lease_connection
      end

      # When connections are established in the future, begin a transaction too
      @connection_subscriber = ActiveSupport::Notifications.subscribe("!connection.active_record") do |*, payload|
        connection_name = payload[:connection_name] if payload.key?(:connection_name)
        shard = payload[:shard] if payload.key?(:shard)
        next unless connection_name

        pool = ActiveRecord::Base.connection_handler.retrieve_connection_pool(connection_name, shard: shard)
        next unless pool

        setup_shared_connection_pool

        unless @connection_pools.include?(pool)
          pool.pin_connection!(true)
          pool.lease_connection
          @connection_pools << pool
        end
      end

      @initializer_hooks.run(:after_transaction_start)
    end

    def rollback_transaction
      return if @connection_pools.blank?

      ActiveSupport::Notifications.unsubscribe(@connection_subscriber) if @connection_subscriber

      @connection_pools.each(&:unpin_connection!)
      @connection_pools.clear

      ActiveRecord::Base.connection_handler.clear_active_connections!
    end
  end
end
