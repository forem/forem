Bundler.require

require 'get_process_mem'
require 'test/unit'

def fixture_path(name = nil)
  path = Pathname.new(File.expand_path("../fixtures", __FILE__))
  return path.join(name) if name
  path
end