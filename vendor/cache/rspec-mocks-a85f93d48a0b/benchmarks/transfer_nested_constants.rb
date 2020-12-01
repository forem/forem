$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require 'benchmark'
require 'rspec/mocks'

N = ENV.fetch('N', 10_000).to_i
M = ENV.fetch('M', 5).to_i

puts "#{N} times, #{M} constants - ruby #{RUBY_VERSION}"
puts

class A
  M.times do |x|
    const_set("C#{x}", Object.new)
  end
end

Benchmark.bm(20) do |bm|
  RSpec::Mocks.setup(self)

  bm.report("with constants") do
    N.times do
      class_double('A').as_stubbed_const(:transfer_nested_constants => true)
    end
  end

  bm.report("without constants") do
    N.times do
      class_double('A').as_stubbed_const(:transfer_nested_constants => false)
    end
  end
end

# > for n in 1 10000; do for m in 0 5 100; do echo; \
#     env N=$n M=$m ruby benchmarks/transfer_nested_constants.rb; \
#   echo; done; done
#
# 1 times, 0 constants - ruby 2.0.0
#
#                            user     system      total        real
# with constants         0.000000   0.000000   0.000000 (  0.000180)
# without constants      0.000000   0.000000   0.000000 (  0.000071)
#
#
# 1 times, 5 constants - ruby 2.0.0
#
#                            user     system      total        real
# with constants         0.000000   0.000000   0.000000 (  0.000197)
# without constants      0.000000   0.000000   0.000000 (  0.000123)
#
#
# 1 times, 100 constants - ruby 2.0.0
#
#                            user     system      total        real
# with constants         0.000000   0.000000   0.000000 (  0.000433)
# without constants      0.000000   0.000000   0.000000 (  0.000115)
#
#
# 10000 times, 0 constants - ruby 2.0.0
#
#                            user     system      total        real
# with constants         0.900000   0.020000   0.920000 (  0.935583)
# without constants      0.660000   0.010000   0.670000 (  0.680178)
#
#
# 10000 times, 5 constants - ruby 2.0.0
#
#                            user     system      total        real
# with constants         1.080000   0.020000   1.100000 (  1.114722)
# without constants      0.720000   0.020000   0.740000 (  0.741976)
#
#
# 10000 times, 100 constants - ruby 2.0.0
#
#                            user     system      total        real
# with constants         3.870000   0.110000   3.980000 (  4.000176)
# without constants      0.930000   0.010000   0.940000 (  0.947197)
