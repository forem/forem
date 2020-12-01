require 'benchmark/ips'

def yield_control
  yield
end

def capture_block_and_yield(&block)
  yield
end

def capture_block_and_call(&block)
  block.call
end

puts "Using the block directly"

Benchmark.ips do |x|
  x.report("yield                  ") do
    yield_control { }
  end

  x.report("capture block and yield") do
    capture_block_and_yield { }
  end

  x.report("capture block and call ") do
    capture_block_and_call { }
  end
end

puts "Forwarding the block to another method"

def tap_with_yield
  5.tap { |i| yield i }
end

def tap_with_forwarded_block(&block)
  5.tap(&block)
end

Benchmark.ips do |x|
  x.report("tap { |i| yield i }") do
    tap_with_yield { |i| }
  end

  x.report("tap(&block)        ") do
    tap_with_forwarded_block { |i| }
  end
end

def yield_n_times(n)
  n.times { yield }
end

def forward_block_to_n_times(n, &block)
  n.times(&block)
end

def call_block_n_times(n, &block)
  n.times { block.call }
end

[10, 25, 50, 100, 1000, 10000].each do |count|
  puts "Invoking the block #{count} times"

  Benchmark.ips do |x|
    x.report("#{count}.times { yield }     ") do
      yield_n_times(count) { }
    end

    x.report("#{count}.times(&block)       ") do
      forward_block_to_n_times(count) { }
    end

    x.report("#{count}.times { block.call }") do
      call_block_n_times(count) { }
    end
  end
end

__END__

This benchmark demonstrates that capturing a block (e.g. `&block`) has
a high constant cost, taking about 5x longer than a single `yield`
(even if the block is never used!).

However, fowarding a captured block can be faster than using `yield`
if the block is used many times (the breakeven point is at about 20-25
invocations), so it appears that he per-invocation cost of `yield`
is higher than that of a captured-and-forwarded block.

Note that there is no circumstance where using `block.call` is faster.

See also `flat_map_vs_inject.rb`, which appears to contradict these
results a little bit.

Using the block directly
Calculating -------------------------------------
yield
                        91.539k i/100ms
capture block and yield
                        50.945k i/100ms
capture block and call
                        50.923k i/100ms
-------------------------------------------------
yield
                          4.757M (± 6.0%) i/s -     23.709M
capture block and yield
                          1.112M (±20.7%) i/s -      5.349M
capture block and call
                        964.475k (±20.3%) i/s -      4.634M
Forwarding the block to another method
Calculating -------------------------------------
 tap { |i| yield i }    74.620k i/100ms
 tap(&block)            51.382k i/100ms
-------------------------------------------------
 tap { |i| yield i }      3.213M (± 6.3%) i/s -     16.043M
 tap(&block)            970.418k (±18.6%) i/s -      4.727M
Invoking the block 10 times
Calculating -------------------------------------
10.times { yield }
                        49.151k i/100ms
10.times(&block)
                        40.682k i/100ms
10.times { block.call }
                        27.576k i/100ms
-------------------------------------------------
10.times { yield }
                        908.673k (± 4.9%) i/s -      4.571M
10.times(&block)
                        674.565k (±16.1%) i/s -      3.336M
10.times { block.call }
                        385.056k (±10.3%) i/s -      1.930M
Invoking the block 25 times
Calculating -------------------------------------
25.times { yield }
                        29.874k i/100ms
25.times(&block)
                        30.934k i/100ms
25.times { block.call }
                        17.119k i/100ms
-------------------------------------------------
25.times { yield }
                        416.342k (± 3.6%) i/s -      2.091M
25.times(&block)
                        446.108k (±10.6%) i/s -      2.227M
25.times { block.call }
                        201.264k (± 7.2%) i/s -      1.010M
Invoking the block 50 times
Calculating -------------------------------------
50.times { yield }
                        17.690k i/100ms
50.times(&block)
                        21.760k i/100ms
50.times { block.call }
                         9.961k i/100ms
-------------------------------------------------
50.times { yield }
                        216.195k (± 5.7%) i/s -      1.079M
50.times(&block)
                        280.217k (± 9.9%) i/s -      1.393M
50.times { block.call }
                        112.754k (± 5.6%) i/s -    567.777k
Invoking the block 100 times
Calculating -------------------------------------
100.times { yield }
                        10.143k i/100ms
100.times(&block)
                        13.688k i/100ms
100.times { block.call }
                         5.551k i/100ms
-------------------------------------------------
100.times { yield }
                        111.700k (± 3.6%) i/s -    568.008k
100.times(&block)
                        163.638k (± 7.7%) i/s -    821.280k
100.times { block.call }
                         58.472k (± 5.6%) i/s -    294.203k
Invoking the block 1000 times
Calculating -------------------------------------
1000.times { yield }
                         1.113k i/100ms
1000.times(&block)
                         1.817k i/100ms
1000.times { block.call }
                       603.000  i/100ms
-------------------------------------------------
1000.times { yield }
                         11.156k (± 8.4%) i/s -     56.763k
1000.times(&block)
                         18.551k (±10.1%) i/s -     92.667k
1000.times { block.call }
                          6.206k (± 3.5%) i/s -     31.356k
Invoking the block 10000 times
Calculating -------------------------------------
10000.times { yield }
                       113.000  i/100ms
10000.times(&block)
                       189.000  i/100ms
10000.times { block.call }
                        61.000  i/100ms
-------------------------------------------------
10000.times { yield }
                          1.150k (± 3.6%) i/s -      5.763k
10000.times(&block)
                          1.896k (± 6.9%) i/s -      9.450k
10000.times { block.call }
                        624.401  (± 3.0%) i/s -      3.172k
