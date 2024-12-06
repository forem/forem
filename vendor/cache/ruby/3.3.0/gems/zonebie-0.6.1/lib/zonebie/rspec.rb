require File.expand_path('../zonebie', File.dirname(__FILE__))

RSpec.configure do |c|
  c.before(:suite) do
    Zonebie.set_random_timezone
  end
end
