require 'benchmark'
require 'rspec/expectations'

include RSpec::Expectations
include RSpec::Matchers

RSpec::Matchers.define :eq_using_dsl do |expected|
  match do |actual|
    actual == expected
  end
end

n = 1000

puts "3 runs of #{n} times for each example running #{RUBY_ENGINE}/#{RUBY_VERSION}"

puts "passing examples: 5.should eq(5)"
puts "* using the DSL"
Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do
        5.should eq_using_dsl(5)
      end
    end
  end
end

puts
puts "* using a class"
Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do
        5.should eq(5)
      end
    end
  end
end

puts
puts "failing examples: 5.should eq(3)"
puts "* using the DSL"
Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do
        5.should eq_using_dsl(3) rescue nil
      end
    end
  end
end

puts
puts "* using a class"
Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do
        5.should eq(3) rescue nil
      end
    end
  end
end

# 3 runs of 1000 times for each example running ruby/1.8.7
# passing examples: 5.should eq(5)
# * using the DSL
#   0.340000   0.000000   0.340000 (  0.342052)
#   0.330000   0.010000   0.340000 (  0.340618)
#   0.340000   0.000000   0.340000 (  0.339149)
#
# * using a class
#   0.000000   0.000000   0.000000 (  0.003762)
#   0.010000   0.000000   0.010000 (  0.004192)
#   0.000000   0.000000   0.000000 (  0.003791)
#
# failing examples: 5.should eq(3)
# * using the DSL
#   0.380000   0.000000   0.380000 (  0.384415)
#   0.380000   0.010000   0.390000 (  0.381604)
#   0.370000   0.000000   0.370000 (  0.380255)
#
# * using a class
#   0.040000   0.000000   0.040000 (  0.034528)
#   0.030000   0.000000   0.030000 (  0.032021)
#   0.060000   0.010000   0.070000 (  0.067579)
#
# 3 runs of 1000 times for each example running ruby/1.9.2
# passing examples: 5.should eq(5)
# * using the DSL
#   0.250000   0.010000   0.260000 (  0.249692)
#   0.250000   0.000000   0.250000 (  0.253856)
#   0.230000   0.000000   0.230000 (  0.232787)
#
# * using a class
#   0.000000   0.000000   0.000000 (  0.001069)
#   0.000000   0.000000   0.000000 (  0.001041)
#   0.000000   0.000000   0.000000 (  0.001023)
#
# failing examples: 5.should eq(3)
# * using the DSL
#   0.370000   0.000000   0.370000 (  0.377139)
#   0.360000   0.010000   0.370000 (  0.358379)
#   0.370000   0.000000   0.370000 (  0.373795)
#
# * using a class
#   0.060000   0.010000   0.070000 (  0.073325)
#   0.050000   0.000000   0.050000 (  0.053562)
#   0.070000   0.000000   0.070000 (  0.075382)
#
# 3 runs of 1000 times for each example running ruby/1.9.3
# passing examples: 5.should eq(5)
# * using the DSL
#     0.210000   0.000000   0.210000 (  0.219539)
#    0.220000   0.010000   0.230000 (  0.217905)
#    0.220000   0.000000   0.220000 (  0.219657)
#
# * using a class
#     0.000000   0.000000   0.000000 (  0.001054)
#    0.000000   0.000000   0.000000 (  0.001048)
#    0.000000   0.000000   0.000000 (  0.001035)
#
# failing examples: 5.should eq(3)
# * using the DSL
#     0.350000   0.000000   0.350000 (  0.351742)
#    0.360000   0.000000   0.360000 (  0.362456)
#    0.340000   0.010000   0.350000 (  0.351098)
#
# * using a class
#     0.080000   0.000000   0.080000 (  0.079964)
#    0.080000   0.000000   0.080000 (  0.076579)
#    0.070000   0.000000   0.070000 (  0.080587)
#
# 3 runs of 1000 times for each example running rbx/1.8.7
# passing examples: 5.should eq(5)
# * using the DSL
#   1.926107   0.009784   1.935891 (  1.629354)
#   0.583860   0.004390   0.588250 (  0.580396)
#   0.868571   0.003510   0.872081 (  0.796644)
#
# * using a class
#   0.002652   0.000013   0.002665 (  0.002679)
#   0.001845   0.000016   0.001861 (  0.001848)
#   0.002656   0.000010   0.002666 (  0.001823)
#
# failing examples: 5.should eq(3)
# * using the DSL
#   0.694148   0.002006   0.696154 (  0.648551)
#   1.063773   0.004653   1.068426 (  0.998837)
#   0.643594   0.001356   0.644950 (  0.638358)
#
# * using a class
#   0.020139   0.000036   0.020175 (  0.020161)
#   0.097540   0.000575   0.098115 (  0.084680)
#   0.058366   0.000269   0.058635 (  0.044372)
#
# 3 runs of 1000 times for each example running jruby/1.8.7
# passing examples: 5.should eq(5)
# * using the DSL
#   0.355000   0.000000   0.355000 (  0.355000)
#   0.261000   0.000000   0.261000 (  0.261000)
#   0.242000   0.000000   0.242000 (  0.242000)
#
# * using a class
#   0.007000   0.000000   0.007000 (  0.007000)
#   0.004000   0.000000   0.004000 (  0.004000)
#   0.001000   0.000000   0.001000 (  0.001000)
#
# failing examples: 5.should eq(3)
# * using the DSL
#   0.507000   0.000000   0.507000 (  0.507000)
#   0.468000   0.000000   0.468000 (  0.468000)
#   0.476000   0.000000   0.476000 (  0.476000)
#
# * using a class
#   0.259000   0.000000   0.259000 (  0.259000)
#   0.521000   0.000000   0.521000 (  0.521000)
#   0.244000   0.000000   0.244000 (  0.244000)
#
