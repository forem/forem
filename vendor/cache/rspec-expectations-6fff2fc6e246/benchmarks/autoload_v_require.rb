require 'benchmark'

n = 10

Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do
        `bin/rspec benchmarks/example_spec.rb`
      end
    end
  end
end

# Before autoloading matcher class files
#    0.000000   0.010000   8.800000 (  8.906383)
#    0.010000   0.010000   8.880000 (  8.980907)
#    0.000000   0.010000   8.820000 (  8.918083)
#
# After autoloading matcher class files
#    0.000000   0.010000   8.610000 (  8.701434)
#    0.010000   0.010000   8.620000 (  8.741811)
#    0.000000   0.000000   8.580000 (  8.677235)
#
# Roughly 2.5% improvement in load time (every bit counts!)
