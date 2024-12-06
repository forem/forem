$: << File.join(__dir__, '..', '..', 'sample')

require 'minitest'
require 'minitest/autorun'

class MultipleExtensionTest < Minitest::Test
  def test_multiple_extensions
    # Rinse
    require 'map/map'
    m = Std::Map.new
    m[0] = 1

    # And repeat
    require 'enum/sample_enum'
    m = Std::Map.new
    m[0] = 1
  end
end
