return unless Rails.env.test?
require "./lib/external_service"

Rails.application.load_tasks unless defined?(Rake::Task)

CypressRails.hooks.before_server_start do
  # Add our fixtures before the resettable transaction is started
  Rake::Task["db:fixtures:load"].invoke
end

CypressRails.hooks.after_server_start do
  # After the server has  booted we add the compliment to the existing fixture list!
  Compliment.create(text: "This shall be the first.")
  if Compliment.count == 4
    raise "I cannot run tests without compliments!"
  end

  # Start up external service
  ExternalService.start_service
end

CypressRails.hooks.after_transaction_start do
  # After each transaction, add this compliment (will be rolled back on reset)
  Compliment.create(text: "You are courageous")
end

CypressRails.hooks.after_state_reset do
  if Compliment.count != 4
    raise "Wait I was expecting exactly 4 compliments!"
  end
end

CypressRails.hooks.before_server_stop do
  # Purge and reload the test database so we don't leave our fixtures in there
  Rake::Task["db:test:prepare"].invoke
end
