require 'rails/all'

module RSpecRails
  class Application < ::Rails::Application
    config.secret_key_base = 'ASecretString'

    if defined?(ActionCable)
      ActionCable.server.config.cable = {"adapter" => "test"}
      ActionCable.server.config.logger =
        ActiveSupport::TaggedLogging.new ActiveSupport::Logger.new(StringIO.new)
    end
  end

  def self.world
    @world
  end

  def self.world=(world)
    @world = world
  end
end

I18n.enforce_available_locales = true

require 'rspec/support/spec'
require 'rspec/core/sandbox'
require 'rspec/rails'
require 'ammeter/init'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

class RSpec::Core::ExampleGroup
  def self.run_all(reporter = nil)
    run(reporter || RSpec::Mocks::Mock.new('reporter').as_null_object)
  end
end

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.max_formatted_output_length = 1000
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
    mocks.verify_doubled_constant_names = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.order = :random
  Kernel.srand config.seed

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.disable_monkey_patching!

  config.warnings = true
  config.raise_on_warning = true

  # Execute a provided block with RSpec global objects (configuration,
  # world, current example) reset. This is used to test specs with RSpec.
  config.around(:example) do |example|
    RSpec::Core::Sandbox.sandboxed do |sandbox_config|
      # If there is an example-within-an-example, we want to make sure the inner
      # example does not get a reference to the outer example (the real spec) if
      # it calls something like `pending`.
      sandbox_config.before(:context) { RSpec.current_example = nil }
      RSpec::Rails.initialize_configuration(sandbox_config)
      example.run
    end
  end
end
