require 'benchmark'

n = 20

Benchmark.benchmark do |bm|
  3.times.each do
    bm.report do
      n.times do
        pid = fork do
          require 'rspec/core'
        end
        Process.wait(pid)
      end
    end
  end
end

# ###################################
# Ruby 1.9.3 - 3 x 20
# require
# $ bundle exec ruby benchmarks/require_relative_v_require.rb
#    0.000000   0.020000   2.540000 (  2.568784)
#    0.000000   0.010000   2.550000 (  2.580621)
#    0.000000   0.020000   2.510000 (  2.548631)
#
# require_relative
# $ bundle exec ruby benchmarks/require_relative_v_require.rb
#    0.000000   0.010000   2.220000 (  2.288229)
#    0.000000   0.010000   2.250000 (  2.289886)
#    0.000000   0.020000   2.260000 (  2.296639)
#
# roughly 12% improvement
#
# ###################################
#
# Ruby 1.8.7 - 3 x 20
# before change (using require, but no conditional)
# $ bundle exec ruby benchmarks/require_relative_v_require.rb
#   0.000000   0.010000   1.210000 (  1.242291)
#   0.000000   0.010000   1.230000 (  1.259518)
#   0.000000   0.010000   1.230000 (  1.250333)
#
# after change (still using require, but adding conditional)
# $ bundle exec ruby benchmarks/require_relative_v_require.rb
#   0.000000   0.010000   1.200000 (  1.227249)
#   0.000000   0.010000   1.230000 (  1.257012)
#   0.000000   0.010000   1.230000 (  1.259278)
#
# virtually no penalty
#
# ###################################

__END__

Ruby 2.0:

➜  rspec-core git:(benchmark-require-relative) REQUIRE_RELATIVE=1 bundle exec ruby benchmarks/require_relative_v_require.rb
   0.000000   0.030000   1.470000 (  1.481949)
   0.000000   0.020000   1.440000 (  1.462620)
   0.000000   0.020000   1.470000 (  1.491825)
➜  rspec-core git:(benchmark-require-relative) bundle exec ruby benchmarks/require_relative_v_require.rb
   0.000000   0.010000   1.510000 (  1.549906)
   0.000000   0.010000   1.530000 (  1.546252)
   0.000000   0.020000   1.510000 (  1.531644)

Ruby 2.1:

➜  rspec-core git:(benchmark-require-relative) bundle exec ruby benchmarks/require_relative_v_require.rb
   0.000000   0.020000   1.570000 (  1.613217)
   0.000000   0.020000   1.600000 (  1.618540)
   0.010000   0.020000   1.570000 (  1.608205)
➜  rspec-core git:(benchmark-require-relative) REQUIRE_RELATIVE=1 bundle exec ruby benchmarks/require_relative_v_require.rb
   0.000000   0.020000   1.480000 (  1.515131)
   0.000000   0.010000   1.480000 (  1.527766)
   0.000000   0.020000   1.490000 (  1.515631)
