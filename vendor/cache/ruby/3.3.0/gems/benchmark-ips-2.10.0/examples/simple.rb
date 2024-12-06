#!/usr/bin/env ruby

require 'benchmark/ips'

Benchmark.ips do |x|

  # Configure the number of seconds used during
  # the warmup phase and calculation phase
  x.config(:time => 5, :warmup => 2)

  # These parameters can also be configured this way
  x.time = 5
  x.warmup = 2

  # Typical mode, runs the block as many times as it can
  x.report("addition") { 1 + 2 }

  # To reduce overhead, the number of iterations is passed in
  # and the block must run the code the specific number of times.
  # Used for when the workload is very small and any overhead
  # introduces incorrectable errors.
  x.report(:addition2) do |times|
    i = 0
    while i < times
      1 + 2
      i += 1
    end
  end

  # To reduce overhead even more, grafts the code given into
  # the loop that performs the iterations internally to reduce
  # overhead. Typically not needed, use the |times| form instead.
  x.report("addition3", "1 + 2")

  # Really long labels should be formatted correctly
  x.report("addition-test-long-label") { 1 + 2 }

  x.compare!
end

puts <<-EOD
Typical results will show addition2 & addition3 to be the most performant, and
they should perform reasonably similarly. You should see addition and
addition-test-long-label to perform very similarly to each other (as they are
running the same test, just with different labels), and they should both run in
the neighborhood of 3.5 times slower than addition2 and addition3."
EOD
