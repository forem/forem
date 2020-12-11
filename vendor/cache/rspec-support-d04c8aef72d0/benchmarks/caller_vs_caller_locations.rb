require 'benchmark/ips'

Benchmark.ips do |x|
  x.report("caller()              ") { caller }
  x.report("caller_locations()    ") { caller_locations }
  x.report("caller(1, 2)          ") { caller(1, 2) }
  x.report("caller_locations(1, 2)") { caller_locations(1, 2) }
end

__END__

caller()
                        118.586k (±17.7%) i/s -    573.893k
caller_locations()
                        355.988k (±17.8%) i/s -      1.709M
caller(1, 2)
                        336.841k (±18.6%) i/s -      1.615M
caller_locations(1, 2)
                        781.330k (±23.5%) i/s -      3.665M
