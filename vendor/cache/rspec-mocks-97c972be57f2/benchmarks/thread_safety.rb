$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require 'benchmark'
require 'rspec/mocks'

Benchmark.bm do |bm|
  bm.report("fetching a proxy") do
    RSpec::Mocks.with_temporary_scope do
      o = Object.new
      100_000.times {
        RSpec::Mocks.space.proxy_for(o)
      }
    end
  end
end

# Without synchronize (not thread-safe):
#
#       user     system      total        real
# fetching a proxy  0.120000   0.000000   0.120000 (  0.141333)
#
# With synchronize (thread-safe):
#       user     system      total        real
# fetching a proxy  0.180000   0.000000   0.180000 (  0.189553)
