require 'benchmark'

n = 1_000_000

puts "Kernel.respond_to?(:warn)"

Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do
       Kernel.respond_to?(:warn)
      end
    end
  end
end

puts "defined?(warn)"

Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do
        defined?(warn)
      end
    end
  end
end

puts "Kernel.respond_to?(:foo)"

Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do
        Kernel.respond_to?(:foo)
      end
    end
  end
end

puts "defined?(foo)"

Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do
        defined?(foo)
      end
    end
  end
end

# $ ruby benchmarks/respond_to_v_defined.rb
# Kernel.respond_to?(:warn)
#    0.190000   0.000000   0.190000 (  0.206502)
#    0.190000   0.000000   0.190000 (  0.197547)
#    0.190000   0.000000   0.190000 (  0.189731)
# defined?(warn)
#    0.190000   0.000000   0.190000 (  0.187334)
#    0.180000   0.000000   0.180000 (  0.201078)
#    0.190000   0.000000   0.190000 (  0.202295)
# Kernel.respond_to?(:foo)
#    0.250000   0.010000   0.260000 (  0.255003)
#    0.240000   0.000000   0.240000 (  0.247376)
#    0.250000   0.000000   0.250000 (  0.251196)
# defined?(foo)
#    0.100000   0.000000   0.100000 (  0.104748)
#    0.110000   0.000000   0.110000 (  0.107250)
#    0.110000   0.000000   0.110000 (  0.107990)
#
# defined is consistently faster, but it takes 1,000,000 x to have a meaningful
# diff
