require 'benchmark'

n = 10_000

num_modules = 1000

class Foo; end
modules = num_modules.times.map { Module.new }
modules.each {|m| Foo.send(:include, m) }

Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do
        Foo < modules.first
      end
    end
  end
end

Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do
        Foo < modules.last
      end
    end
  end
end

Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do
        Foo.included_modules.include?(modules.first)
      end
    end
  end
end

Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do
        Foo.included_modules.include?(modules.last)
      end
    end
  end
end

#### Ruby 1.9.3
#
# 100 modules
# < modules.first
  # 0.010000   0.000000   0.010000 (  0.005104)
  # 0.000000   0.000000   0.000000 (  0.005114)
  # 0.010000   0.000000   0.010000 (  0.005076)
# < modules.last
  # 0.000000   0.000000   0.000000 (  0.002180)
  # 0.000000   0.000000   0.000000 (  0.002199)
  # 0.000000   0.000000   0.000000 (  0.002189)
# < included_modules.include?(modules.first)
  # 0.110000   0.010000   0.120000 (  0.110062)
  # 0.100000   0.000000   0.100000 (  0.105343)
  # 0.100000   0.000000   0.100000 (  0.102770)
# < included_modules.include?(modules.last)
  # 0.050000   0.010000   0.060000 (  0.048520)
  # 0.040000   0.000000   0.040000 (  0.049013)
  # 0.050000   0.000000   0.050000 (  0.050668)

# 1000 modules
# < modules.first
  # 0.080000   0.000000   0.080000 (  0.079460)
  # 0.080000   0.000000   0.080000 (  0.078765)
  # 0.080000   0.000000   0.080000 (  0.079560)
# < modules.last
  # 0.000000   0.000000   0.000000 (  0.002195)
  # 0.000000   0.000000   0.000000 (  0.002201)
  # 0.000000   0.000000   0.000000 (  0.002199)
# < included_modules.include?(modules.first)
  # 0.860000   0.010000   0.870000 (  0.887684)
  # 0.870000   0.000000   0.870000 (  0.875158)
  # 0.870000   0.000000   0.870000 (  0.879216)
# < included_modules.include?(modules.last)
  # 0.340000   0.000000   0.340000 (  0.344011)
  # 0.350000   0.000000   0.350000 (  0.346277)
  # 0.330000   0.000000   0.330000 (  0.335607)

#### Ruby 1.8.7
#
# 100 modules
# < modules.first
  # 0.010000   0.000000   0.010000 (  0.007132)
  # 0.010000   0.000000   0.010000 (  0.006869)
  # 0.000000   0.000000   0.000000 (  0.005334)
# < modules.last
  # 0.010000   0.000000   0.010000 (  0.003438)
  # 0.000000   0.000000   0.000000 (  0.003454)
  # 0.000000   0.000000   0.000000 (  0.003408)
# < included_modules.include?(modules.first)
  # 0.110000   0.010000   0.120000 (  0.113255)
  # 0.110000   0.000000   0.110000 (  0.112880)
  # 0.110000   0.000000   0.110000 (  0.121003)
# < included_modules.include?(modules.last)
  # 0.040000   0.010000   0.050000 (  0.040736)
  # 0.040000   0.000000   0.040000 (  0.039609)
  # 0.030000   0.000000   0.030000 (  0.039888)

# 1000 modules
# < modules.first
  # 0.040000   0.000000   0.040000 (  0.044124)
  # 0.050000   0.000000   0.050000 (  0.046110)
  # 0.040000   0.000000   0.040000 (  0.042603)
# < modules.last
  # 0.000000   0.000000   0.000000 (  0.003405)
  # 0.010000   0.000000   0.010000 (  0.005510)
  # 0.000000   0.000000   0.000000 (  0.003562)
# < included_modules.include?(modules.first)
  # 0.990000   0.000000   0.990000 (  1.096331)
  # 1.030000   0.010000   1.040000 (  1.047791)
  # 0.990000   0.000000   0.990000 (  1.019169)
# < included_modules.include?(modules.last)
  # 0.260000   0.000000   0.260000 (  0.265306)
  # 0.270000   0.000000   0.270000 (  0.311985)
  # 0.270000   0.000000   0.270000 (  0.277936)
