# Require this either in your Gemfile or in your minitest configuration.
# Examples:
#
#   # Gemfile
#   group :test do
#     gem 'minitest'
#     gem 'fakeredis', :require => 'fakeredis/minitest'
#   end
#
#   # test/test_helper.rb (or test/minitest_config.rb)
#   require 'fakeredis/minitest'

require 'fakeredis'

module FakeRedis
  module Minitest
    def setup
      Redis::Connection::Memory.reset_all_databases
      super
    end

    ::Minitest::Test.send(:include, self)
  end
end
