# We want to check not only if we are in the test environment, but also if we are
# running E2E tests. Otherwise this will run when system tests run.
return unless Rails.env.test? && ENV["E2E"].present?

CypressRails.hooks.before_server_start do
  # Called once, before either the transaction or the server is started
  Rails.logger.info("Starting up server for end to end tests.")
  Rails.application.load_tasks
  Rake::Task["db:seed:e2e"].invoke
end

CypressRails.hooks.after_transaction_start do
  # Called after the transaction is started (at launch and after each reset)
end

CypressRails.hooks.after_state_reset do
  # Triggered after `/cypress_rails_reset_state` is called
end

CypressRails.hooks.before_server_stop do
  # Called once, at_exit
  Rails.logger.info("Cleaning up and stopping server for end to end tests.")
  Rake::Task["search:destroy"].invoke
  Rake::Task["db:truncate_all"].invoke
  Rails.logger.info("The end to end test server has shutdown gracefully.")
end
