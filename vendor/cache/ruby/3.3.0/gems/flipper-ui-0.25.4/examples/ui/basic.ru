#
# Usage:
#   # if you want it to not reload and be really fast
#   bin/rackup examples/ui/basic.ru -p 9999
#
#   # if you want reloading
#   bin/shotgun examples/ui/basic.ru -p 9999
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
  # config.banner_text = 'Production Environment'
  # config.banner_class = 'danger'
  config.feature_creation_enabled = true
  config.feature_removal_enabled = true
  config.cloud_recommendation = true
  config.confirm_fully_enable = true
  # config.show_feature_description_in_list = true
  config.descriptions_source = lambda do |_keys|
    {
      "search_performance_another_long_thing" => "Just to test feature name length.",
      "gauges_tracking" => "Should we track page views with gaug.es.",
      "unused" => "Not used.",
      "suits" => "Are suits necessary in business?",
      "secrets" => "Secrets are lies.",
      "logging" => "Log all the things.",
      "new_cache" => "Like the old cache but newer.",
      "a/b" => "Why would someone use a slash? I don't know but someone did. Let's make this really long so they regret using slashes. Please don't use slashes.",
    }
  end
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
