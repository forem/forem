# Base
# require 'rubygems'
require 'bundler/setup'

# Testing
require 'rspec'
require 'rspec/its'
require 'rspec/mocks'

# Support files, order is relevant
require File.join(File.dirname(__FILE__), 'support', 'socket_hostname')
require File.join(File.dirname(__FILE__), 'support', 'timecop')
require File.join(File.dirname(__FILE__), 'support', 'webmock')
require File.join(File.dirname(__FILE__), 'support', 'timber')

# Load framework files after we've setup everything
if !ENV["RAILS_23"]
  require File.join(File.dirname(__FILE__), 'support', 'rails')
  require File.join(File.dirname(__FILE__), 'support', 'action_controller')
  require File.join(File.dirname(__FILE__), 'support', 'active_record')
end

RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length = 5_000

RSpec.configure do |config|
  config.color = true
  config.order = :random
  config.warnings = false

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
