require 'benchmark'

$n = 10000
size = 100

puts "size: #{size}"
puts

def report
  reals = []
  Benchmark.benchmark do |bm|
    3.times do
      reals << bm.report { $n.times { yield } }.real
    end
  end

  reals.inject(&:+) / reals.count
end

avgs = []

puts "map then flatten"
avgs << report {
  (1..size).
    map {|n| [n]}.
    flatten
}

puts

puts "flat_map"
avgs << report {
  (1..size).
    flat_map {|n| [n]}
}

puts avgs
if avgs[0] < avgs[1]
  puts "map then flatten faster by #{((1.0 - avgs[0]/avgs[1]) * 100).round(2)} %"
else
  puts "flat_map faster by #{((1.0 - avgs[1]/avgs[0]) * 100).round(2)} %"
end

__END__

for each size (10, 100, 1000) showing smallest diff
  between map-then-flatten and flat_map in at least
  5 runs

size: 10

map then flatten
   0.550000   0.000000   0.550000 (  0.547897)
   0.570000   0.000000   0.570000 (  0.565139)
   0.550000   0.000000   0.550000 (  0.557421)

flat_map
   0.320000   0.000000   0.320000 (  0.316801)
   0.320000   0.010000   0.330000 (  0.325373)
   0.330000   0.000000   0.330000 (  0.325169)

flat_map faster by 42.09 %

**********************************************

size: 100

map then flatten
   0.390000   0.000000   0.390000 (  0.387307)
   0.390000   0.000000   0.390000 (  0.387630)
   0.380000   0.000000   0.380000 (  0.389421)

flat_map
   0.250000   0.000000   0.250000 (  0.259444)
   0.270000   0.000000   0.270000 (  0.261972)
   0.250000   0.000000   0.250000 (  0.252584)

flat_map faster by 33.53 %

**********************************************

size: 1000

map then flatten
   0.380000   0.000000   0.380000 (  0.382788)
   0.380000   0.000000   0.380000 (  0.372447)
   0.370000   0.000000   0.370000 (  0.370065)

flat_map
   0.240000   0.000000   0.240000 (  0.240357)
   0.240000   0.000000   0.240000 (  0.242325)
   0.240000   0.000000   0.240000 (  0.240985)

flat_map faster by 35.69 %
