require File.expand_path("../lib/zonebie", File.dirname(__FILE__))

RSpec.configure do |c|
  c.mock_with :mocha

  c.before do
    ENV.delete('ZONEBIE_TZ')
    Zonebie.backend = nil # reset to default
  end
end
