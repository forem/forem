require 'benchmark'

n = 10_000

m = 1.upto(1000).inject({}) { |m, i| m[i] = i; m }

Benchmark.benchmark do |bm|
  puts "#{n} times - ruby #{RUBY_VERSION}"

  puts
  puts "each_value"

  3.times do
    bm.report do
      n.times do
        m.each_value {}
      end
    end
  end

  puts
  puts "values.each"

  3.times do
    bm.report do
      n.times do
        m.values.each {}
      end
    end
  end
end

# $ ruby benchmarks/values_each_v_each_value.rb
#  10000 times - ruby 1.9.3
#
# each_value
#    0.720000   0.000000   0.720000 (  0.720237)
#    0.720000   0.000000   0.720000 (  0.724956)
#    0.730000   0.000000   0.730000 (  0.730352)
#
# values.each
#    0.910000   0.000000   0.910000 (  0.917496)
#    0.910000   0.010000   0.920000 (  0.909319)
#    0.910000   0.000000   0.910000 (  0.911225)

# $ ruby benchmarks/values_each_v_each_value.rb
# 10000 times - ruby 2.0.0
#
# each_value
#    0.730000   0.000000   0.730000 (  0.738443)
#    0.720000   0.000000   0.720000 (  0.720183)
#    0.720000   0.000000   0.720000 (  0.720866)
#
# values.each
#    0.940000   0.000000   0.940000 (  0.942597)
#    0.960000   0.010000   0.970000 (  0.959248)
#    0.960000   0.000000   0.960000 (  0.959099)
