require 'rspec'
require 'rspec/core/sandbox'

require 'rspec/retry'
if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2')
  require "pry-debugger"
else
  require "pry-byebug"
end

RSpec.configure do |config|
  config.verbose_retry = true
  config.display_try_failure_messages = true

  config.around :example do |ex|
    RSpec::Core::Sandbox.sandboxed do |config|
      RSpec::Retry.setup
      ex.run
    end
  end

  config.around :each, :overridden do |ex|
    ex.run_with_retry retry: 3
  end

  config.retry_count_condition = ->(example) { example.metadata[:retry_me_once] ? 2 : nil }
end
