ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# NOTE: Ruby 3.3.0 compatibility fix
# In Ruby 3.3.0, the Logger class is not automatically loaded from the standard library.
# This causes issues with ActiveSupport's logger_thread_safe_level.rb which tries to
# use Logger::Severity.constants without requiring Logger first.
require "logger"
