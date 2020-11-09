ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

if !defined?(Spring) && [nil, "development", "test"].include?(ENV["RAILS_ENV"])
  load File.expand_path("../bin/spring", __dir__)
end

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
