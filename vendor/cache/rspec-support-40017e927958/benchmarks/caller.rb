$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require 'benchmark'
require 'rspec/support/caller_filter'

n = 10000

puts "#{n} times - ruby #{RUBY_VERSION}"
puts

puts "* Using a chunked fetch is quicker than the old method of array-access."
Benchmark.bm(20) do |bm|
  bm.report("CallerFilter") do
    n.times do
      RSpec::CallerFilter.first_non_rspec_line
    end
  end

  bm.report("Direct caller access") do
    n.times do
      caller(1)[4]
    end
  end
end

puts
puts "* Chunking fetches of caller adds a ~17% overhead."
Benchmark.bm(20) do |bm|
  bm.report("Chunked") do
    n.times do
      caller(1, 2)
      caller(3, 2)
      caller(5, 2)
    end
  end

  bm.report("All at once") do
    n.times do
      caller(1, 6)
    end
  end
end

puts
puts "* `caller` scales linearly with length parameter."
Benchmark.bm(20) do |bm|
  (1..10).each do |x|
    bm.report(x) do
      n.times do
        caller(1, x)
      end
    end
  end
end


# > ruby benchmarks/caller.rb
# 10000 times - ruby 2.0.0
#
# * Using a chunked fetch is quicker than the old method of array-access.
#                            user     system      total        real
# CallerFilter            0.140000   0.010000   0.150000 (  0.145381)
# Direct caller access   0.170000   0.000000   0.170000 (  0.180610)
#
# * Chunking fetches of caller adds a ~17% overhead.
#                            user     system      total        real
# Chunked                0.150000   0.000000   0.150000 (  0.181162)
# All at once            0.130000   0.010000   0.140000 (  0.138732)
#
# * `caller` scales linearly with length parameter.
#                            user     system      total        real
# 1                      0.030000   0.000000   0.030000 (  0.035000)
# 2                      0.050000   0.000000   0.050000 (  0.059879)
# 3                      0.080000   0.000000   0.080000 (  0.098468)
# 4                      0.090000   0.010000   0.100000 (  0.097619)
# 5                      0.110000   0.000000   0.110000 (  0.126220)
# 6                      0.130000   0.000000   0.130000 (  0.136739)
# 7                      0.150000   0.000000   0.150000 (  0.159055)
# 8                      0.160000   0.010000   0.170000 (  0.172416)
# 9                      0.180000   0.000000   0.180000 (  0.203038)
# 10                     0.200000   0.000000   0.200000 (  0.210551)
