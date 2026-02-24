$LOAD_PATH.unshift("lib")
require "rspec/core"
require "rspec/retry"
RSpec.configure do |config|
  config.verbose_retry = true
  config.display_try_failure_messages = true
  config.default_retry_count = 3
  config.exceptions_to_retry = [StandardError]
end
RSpec.describe "Retry Test" do
  it "fails and retries" do
    puts "Trying..."
    raise "Failed"
  end
end
