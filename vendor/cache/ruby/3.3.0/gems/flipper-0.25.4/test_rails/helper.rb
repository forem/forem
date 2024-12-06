require 'rubygems'
require 'bundler'
Bundler.setup(:default)
require 'rails'
require 'rails/test_help'

begin
  ActiveSupport::TestCase.test_order = :random
rescue NoMethodError
  # no biggie, means we are on older version of AS that doesn't have this option
end
