require "spec_helper"

RSpec.configure do |config|
  config.before(:each) do
    # Disable so we test against actual redis
    FakeRedis.disable

    Redis.new.flushall
  end
end

def fakeredis?
  FakeRedis.enabled?
end
