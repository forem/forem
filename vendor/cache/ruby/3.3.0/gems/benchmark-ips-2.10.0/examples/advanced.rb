#!/usr/bin/env ruby

require 'benchmark/ips'

Benchmark.ips do |x|

  # Use bootstrap confidence intervals
  x.stats = :bootstrap

  # Set confidence to 95%
  x.confidence = 95

  # Run multiple iterations for better warmup
  x.iterations = 3

  x.report("mul") { 2 * 2 * 2 * 2 * 2 * 2 * 2 * 2 }
  x.report("pow") { 2 ** 8 }

  x.compare!
end
