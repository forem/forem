# encoding: UTF-8

# To make testing/debugging easier test within this source tree versus an installed gem
require 'bundler/setup'

# Add ext directory to load path to make it easier to test locally built extensions
ext_path = File.expand_path(File.join(__dir__, '..', 'ext', 'ruby_prof'))
$LOAD_PATH.unshift(File.expand_path(ext_path))

# Now load code
require 'ruby-prof'

# Disable minitest parallel tests. The problem is the thread switching will change test results
# (self vs wait time)
ENV["MT_CPU"] = "0" # New versions of minitest
ENV["N"] = "0" # Older versions of minitest

require 'minitest/autorun'
class TestCase < Minitest::Test
end
