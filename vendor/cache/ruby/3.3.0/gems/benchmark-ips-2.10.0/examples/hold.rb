#!/usr/bin/env ruby
# example to explain hold! usage https://github.com/evanphx/benchmark-ips/issues/85
# The hold! feature expects to be run twice, generally with different Rubys.
# hold! can also be used to compare modules changes which impact the run time
# RUN_1: ruby examples/hold.rb
# Warming up --------------------------------------
#             without   172.168k i/100ms
# Calculating -------------------------------------
#             without      2.656M (± 3.3%) i/s -     13.429M in   5.062098s
#
# RUN_2: WITH_MODULE=true ruby examples/hold.rb
# Warming up --------------------------------------
#                 with    92.087k i/100ms
# Calculating -------------------------------------
#                 with      1.158M (± 1.4%) i/s -      5.801M in   5.010084s
#
# Comparison:
#              without:  2464721.3 i/s
#                 with:  1158179.6 i/s - 2.13x  slower
require 'benchmark/ips'

Benchmark.ips do |x|
  x.report('without') do
    'Bruce'.inspect
  end

  if ENV['WITH_MODULE'] == 'true'
    class String
      def inspect
        result = %w[Bruce Wayne is Batman]
        result.join(' ')
      end
    end
  end

  x.report('with') do
    'Bruce'.inspect
  end
  x.hold! 'temp_results'
  x.compare!
end
