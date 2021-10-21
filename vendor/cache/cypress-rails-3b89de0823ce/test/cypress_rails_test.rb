require "test_helper"

class CypressRailsTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::CypressRails::VERSION
  end
end
