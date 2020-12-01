require 'benchmark'

n = 10_000

class  Foo; end
module Bar; end

Benchmark.benchmark do |bm|
  puts "Class.new(Foo)"

  3.times do
    bm.report do
      n.times do
        Class.new(Foo)
      end
    end
  end

  puts "Class.new { include Bar }"

  3.times do
    bm.report do
      n.times do
        Class.new { include Bar }
      end
    end
  end
end

# $ ruby benchmarks/include_v_superclass.rb
# Class.new(Foo)
#   0.030000   0.000000   0.030000 (  0.033536)
#   0.020000   0.000000   0.020000 (  0.022077)
#   0.040000   0.010000   0.050000 (  0.035813)
# Class.new { include Bar }
#   0.040000   0.000000   0.040000 (  0.041427)
#   0.040000   0.000000   0.040000 (  0.039019)
#   0.030000   0.000000   0.030000 (  0.037018)
