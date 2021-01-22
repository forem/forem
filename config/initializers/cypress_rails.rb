return unless Rails.env.test?

CypressRails.hooks.before_server_start do
  # Called once, before either the transaction or the server is started
  Rails.application.load_tasks
  Rake::Task["db:seed:e2e"].invoke("initial_e2e_db")
end

CypressRails.hooks.after_transaction_start do
  # Called after the transaction is started (at launch and after each reset)
end

CypressRails.hooks.after_state_reset do
  # Triggered after `/cypress_rails_reset_state` is called
end

CypressRails.hooks.before_server_stop do
  # Called once, at_exit
end
