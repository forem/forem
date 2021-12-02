require "cypress-rails/version"

module CypressRails
end

require "cypress-rails/init"
require "cypress-rails/open"
require "cypress-rails/run"
require "cypress-rails/run_knapsack"
require "cypress-rails/resets_state"
require "cypress-rails/initializer_hooks"
require "cypress-rails/railtie" if defined?(Rails)
