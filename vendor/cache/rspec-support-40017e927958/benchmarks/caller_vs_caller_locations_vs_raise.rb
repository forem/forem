# This benchmark arose from rspec/rspec-support#199 where we experimented with
# faster ways of generating / capturing a backtrace and wether it made sense
# to lazily generate it using `raise` to capture the backtrace via an exception.
# See also rspec/rspec-mocks#937

require 'benchmark/ips'

def use_raise_to_capture_caller
  use_raise_lazily.backtrace
end

def use_raise_lazily
  raise "nope"
rescue StandardError => exception
  return exception
end

def create_stack_trace(n, &block)
  return create_stack_trace(n - 1, &block) if n > 0
  yield
end

[10, 50, 100].each do |frames|
  puts "-" * 80
  puts "With #{frames} extra stack frames"
  puts "-" * 80
  create_stack_trace(frames) do
    Benchmark.ips do |x|
      x.report("caller()              ") { caller }
      x.report("caller_locations()    ") { caller_locations }
      x.report("raise with backtrace  ") { use_raise_to_capture_caller }
      x.report("raise and store (lazy)") { use_raise_lazily }
      x.report("caller(1, 2)          ") { caller(1, 2) }
      x.report("caller_locations(1, 2)") { caller_locations(1, 2) }
      x.compare!
    end
  end
end

__END__
--------------------------------------------------------------------------------
With 10 extra stack frames
--------------------------------------------------------------------------------
Calculating -------------------------------------
caller()
                         5.583k i/100ms
caller_locations()
                        14.540k i/100ms
raise with backtrace
                         4.544k i/100ms
raise and store (lazy)
                        27.028k i/100ms
caller(1, 2)
                        25.739k i/100ms
caller_locations(1, 2)
                        48.848k i/100ms
-------------------------------------------------
caller()
                         61.386k (±11.6%) i/s -    307.065k
caller_locations()
                        176.033k (±12.8%) i/s -    872.400k
raise with backtrace
                         48.348k (±10.5%) i/s -    240.832k
raise and store (lazy)
                        425.768k (±10.7%) i/s -      2.108M
caller(1, 2)
                        368.142k (±18.9%) i/s -      1.776M
caller_locations(1, 2)
                        834.431k (±17.8%) i/s -      4.054M

Comparison:
caller_locations(1, 2):   834431.2 i/s
raise and store (lazy):   425767.6 i/s - 1.96x slower
caller(1, 2)          :   368142.0 i/s - 2.27x slower
caller_locations()    :   176032.6 i/s - 4.74x slower
caller()              :    61386.0 i/s - 13.59x slower
raise with backtrace  :    48348.2 i/s - 17.26x slower

--------------------------------------------------------------------------------
With 50 extra stack frames
--------------------------------------------------------------------------------
Calculating -------------------------------------
caller()
                         2.282k i/100ms
caller_locations()
                         6.446k i/100ms
raise with backtrace
                         2.138k i/100ms
raise and store (lazy)
                        23.649k i/100ms
caller(1, 2)
                        22.113k i/100ms
caller_locations(1, 2)
                        36.586k i/100ms
-------------------------------------------------
caller()
                         24.105k (± 9.9%) i/s -    120.946k
caller_locations()
                         68.610k (± 7.9%) i/s -    341.638k
raise with backtrace
                         21.458k (± 9.6%) i/s -    106.900k
raise and store (lazy)
                        341.152k (± 8.1%) i/s -      1.703M
caller(1, 2)
                        297.805k (±12.5%) i/s -      1.482M
caller_locations(1, 2)
                        557.278k (±16.6%) i/s -      2.744M

Comparison:
caller_locations(1, 2):   557278.2 i/s
raise and store (lazy):   341151.6 i/s - 1.63x slower
caller(1, 2)          :   297804.8 i/s - 1.87x slower
caller_locations()    :    68610.3 i/s - 8.12x slower
caller()              :    24105.5 i/s - 23.12x slower
raise with backtrace  :    21458.2 i/s - 25.97x slower

--------------------------------------------------------------------------------
With 100 extra stack frames
--------------------------------------------------------------------------------
Calculating -------------------------------------
caller()
                         1.327k i/100ms
caller_locations()
                         3.773k i/100ms
raise with backtrace
                         1.235k i/100ms
raise and store (lazy)
                        19.990k i/100ms
caller(1, 2)
                        18.269k i/100ms
caller_locations(1, 2)
                        29.668k i/100ms
-------------------------------------------------
caller()
                         13.879k (± 9.9%) i/s -     69.004k
caller_locations()
                         39.070k (± 7.6%) i/s -    196.196k
raise with backtrace
                         12.703k (±12.7%) i/s -     62.985k
raise and store (lazy)
                        243.959k (± 8.3%) i/s -      1.219M
caller(1, 2)
                        230.289k (± 8.2%) i/s -      1.151M
caller_locations(1, 2)
                        406.804k (± 8.8%) i/s -      2.047M

Comparison:
caller_locations(1, 2):   406804.3 i/s
raise and store (lazy):   243958.7 i/s - 1.67x slower
caller(1, 2)          :   230288.9 i/s - 1.77x slower
caller_locations()    :    39069.8 i/s - 10.41x slower
caller()              :    13879.4 i/s - 29.31x slower
raise with backtrace  :    12702.9 i/s - 32.02x slower
