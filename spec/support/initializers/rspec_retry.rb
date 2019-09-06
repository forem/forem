require "rspec/retry"

RSpec.configure do |config|
  config.verbose_retry = true
  config.display_try_failure_messages = true
  config.around :each, :js do |ex|
    # retry only on features in CI
    ex.run_with_retry retry: ENV["CI"] ? 3 : 1
  end
end
