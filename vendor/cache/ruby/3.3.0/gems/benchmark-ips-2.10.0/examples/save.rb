#!/usr/bin/env ruby

# example to explain save!
# The save! feature expects to be run twice, generally with different Rubys.
# save! can also be used to compare modules changes which impact the run time
#
# If you're comparing ruby versions, Just use the version in the label
#
#     x.report("ruby #{RUBY_VERSION}") { 'Bruce'.inspect }
#
# Or use a hash
# 
#     x.report("version" => RUBY_VERSION, "method" => 'bruce') { 'Bruce'.inspect }
#
# RUN_1: SAVE_FILE='run1.out' ruby examples/hold.rb
# Warming up --------------------------------------
#             without   172.168k i/100ms
# Calculating -------------------------------------
#             without      2.656M (± 3.3%) i/s -     13.429M in   5.062098s
#
# RUN_2: SAVE_FILE='run1.out' WITH_MODULE=true ruby examples/hold.rb
# Warming up --------------------------------------
#                 with    92.087k i/100ms
# Calculating -------------------------------------
#                 with      1.158M (± 1.4%) i/s -      5.801M in   5.010084s
#
# Comparison:
#              without:  2464721.3 i/s
#                 with:  1158179.6 i/s - 2.13x  slower
# CLEANUP: rm run1.out

require 'benchmark/ips'

Benchmark.ips do |x|
  x.report(ENV['WITH_MODULE'] == 'true' ? 'with' : 'without') do
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

  x.save! ENV['SAVE_FILE'] if ENV['SAVE_FILE']
  x.compare!
end
