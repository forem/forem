# This file is used by Rack-based servers to start the application.

# Honeycomb must be initialized before the Rails app starts
# see <https://docs.honeycomb.io/getting-data-in/ruby/beeline/> for details
require "honeycomb-beeline"
Honeycomb.init(
  writekey: ENV["HONEYCOMB_API_KEY"],
  # NOTE: dataset should probably be set using "HONEYCOMB_DATASET" env,
  # to avoid hardcoding "dev.to" as a name
  dataset: "dev.to-#{ENV['RAILS_ENV']}",
)

require ::File.expand_path("../config/environment", __FILE__)
run Rails.application
