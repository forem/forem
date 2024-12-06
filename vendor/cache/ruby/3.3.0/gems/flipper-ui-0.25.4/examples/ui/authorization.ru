#
# Usage:
#   bundle exec rackup examples/ui/authorization.ru -p 9999
#   bundle exec shotgun examples/ui/authorization.ru -p 9999
#   http://localhost:9999/
#
require 'bundler/setup'
require "flipper/ui"
require "flipper/adapters/pstore"

Flipper.register(:admins) { |actor|
  actor.respond_to?(:admin?) && actor.admin?
}

# Example middleware to allow reading the Flipper UI but nothing else.
class FlipperReadOnlyMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    if request.get?
      @app.call(env)
    else
      [401, {}, ["You can only look"]]
    end
  end
end

# You can uncomment these to get some default data:
# Flipper.enable(:search_performance_another_long_thing)
# Flipper.disable(:gauges_tracking)
# Flipper.disable(:unused)
# Flipper.enable_actor(:suits, Flipper::Actor.new('1'))
# Flipper.enable_actor(:suits, Flipper::Actor.new('6'))
# Flipper.enable_group(:secrets, :admins)
# Flipper.enable_percentage_of_time(:logging, 5)
# Flipper.enable_percentage_of_actors(:new_cache, 15)
# Flipper.add("a/b")

run Flipper::UI.app { |builder|
  builder.use Rack::Session::Cookie, secret: "_super_secret"
  builder.use FlipperReadOnlyMiddleware
}
