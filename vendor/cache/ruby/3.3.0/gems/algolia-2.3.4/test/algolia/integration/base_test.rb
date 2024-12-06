require 'test_helper'
require 'minitest/hell'

class BaseTest < Minitest::Test
  parallelize_me!
  def setup
    check_environment_variables
  end
end
