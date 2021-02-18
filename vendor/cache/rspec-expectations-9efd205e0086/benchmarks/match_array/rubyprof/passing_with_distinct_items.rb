$LOAD_PATH.unshift "./lib"
require 'rspec/expectations'
require 'securerandom'

extend RSpec::Matchers

actual    = Array.new(1000) { SecureRandom.uuid }
expected  = actual.shuffle
expect(actual).to match_array(expected)
