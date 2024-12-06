require 'rspec'

$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))
$LOAD_PATH.unshift(File.join(__dir__, '..'))
Dir['spec/support/**/*.rb'].each { |f| require f }

require 'fakeredis'
require "fakeredis/rspec"

RSpec.configure do |config|
  # Enable memory adapter
  config.before(:each) { FakeRedis.enable }

  config.backtrace_exclusion_patterns = []
end

def fakeredis?
  FakeRedis.enabled?
end
