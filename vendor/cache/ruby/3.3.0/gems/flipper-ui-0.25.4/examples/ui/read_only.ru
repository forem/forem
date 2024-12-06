#
# Usage:
#   # if you want it to not reload and be really fast
#   bin/rackup examples/ui/read_only.ru -p 9999
#
#   # if you want reloading
#   bin/shotgun examples/ui/read_only.ru -p 9999
#
#   http://localhost:9999/
#
require 'bundler/setup'
require "flipper/ui"
require "flipper/adapters/pstore"

Flipper.register(:admins) { |actor|
  actor.respond_to?(:admin?) && actor.admin?
}

Flipper.register(:early_access) { |actor|
  actor.respond_to?(:early?) && actor.early?
}

Flipper::UI.configure do |config|
  config.banner_text = 'Read only mode.'
  config.banner_class = 'danger'
  config.read_only = true
end

# You can uncomment these to get some default data:
# Flipper.enable(:search_performance_another_long_thing)
# Flipper.disable(:gauges_tracking)
# Flipper.disable(:unused)
# Flipper.enable_actor(:suits, Flipper::Actor.new('1'))
# Flipper.enable_actor(:suits, Flipper::Actor.new('6'))
# Flipper.enable_group(:secrets, :admins)
# Flipper.enable_group(:secrets, :early_access)
# Flipper.enable_percentage_of_time(:logging, 5)
# Flipper.enable_percentage_of_actors(:new_cache, 15)
# Flipper.add("a/b")

run Flipper::UI.app { |builder|
  builder.use Rack::Session::Cookie, secret: "_super_secret"
}
