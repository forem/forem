require_relative "finds_bin"
require_relative "config"
require_relative "initializer_hooks"
require_relative "manages_transactions"
require_relative "starts_rails_server"

module CypressRails
  class LaunchesCypress
    def initialize
      @initializer_hooks = InitializerHooks.instance
      @manages_transactions = ManagesTransactions.instance
      @starts_rails_server = StartsRailsServer.new
      @finds_bin = FindsBin.new
    end

    def call(command, config)
      puts config.to_s
      @initializer_hooks.run(:before_server_start)
      if config.transactional_server
        @manages_transactions.begin_transaction
      end
      server = @starts_rails_server.call(
        host: config.host,
        port: config.port,
        transactional_server: config.transactional_server
      )
      bin = @finds_bin.call(config.dir, config.knapsack)

      set_exit_hooks!(config)

      command = <<~EXEC
        CYPRESS_BASE_URL="http://#{server.host}:#{server.port}#{config.base_path}" "#{bin}" #{command} --project "#{config.dir}" #{config.cypress_cli_opts}
      EXEC

      puts "\nLaunching Cypress…\n$ #{command}\n"
      system command
    end

    private

    def set_exit_hooks!(config)
      at_exit do
        run_exit_hooks_if_necessary!(config)
      end
      Signal.trap("INT") do
        puts "Exiting cypress-rails…"
        exit
      end
    end

    def run_exit_hooks_if_necessary!(config)
      @at_exit_hooks_have_fired ||= false # avoid warning
      return if @at_exit_hooks_have_fired

      if config.transactional_server
        @manages_transactions.rollback_transaction
      end
      @initializer_hooks.run(:before_server_stop)

      @at_exit_hooks_have_fired = true
    end
  end
end
