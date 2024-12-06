require 'test_helper'
require 'flipper/adapters/pstore'

class PstoreTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
    dir = FlipperRoot.join('tmp').tap(&:mkpath)
    pstore_file = dir.join('flipper.pstore')
    pstore_file.unlink if pstore_file.exist?
    @adapter = Flipper::Adapters::PStore.new(pstore_file)
  end

  def test_defaults_path_to_flipper_pstore
    assert_equal Flipper::Adapters::PStore.new.path, 'flipper.pstore'
  end
end
