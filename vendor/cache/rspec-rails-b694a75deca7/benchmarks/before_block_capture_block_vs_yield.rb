require 'benchmark/ips'

def before_n_times(n, &block)
  n.times { instance_exec(&block) }
end

def yield_n_times(n)
  before_n_times(n) { yield }
end

def capture_block_and_yield_n_times(n, &block) # rubocop:disable Lint/UnusedMethodArgument
  before_n_times(n) { yield }
end

def capture_block_and_call_n_times(n, &block)
  before_n_times(n) { block.call }
end

[10, 25, 50, 100, 1000, 10_000].each do |count|
  puts "\n\nInvoking the block #{count} times\n"

  Benchmark.ips do |x|
    x.report("Yield #{count} times                  ") do
      yield_n_times(count) { }
    end

    x.report("Capture block and yield #{count} times") do
      capture_block_and_yield_n_times(count) { }
    end

    x.report("Capture block and call #{count} times ") do
      capture_block_and_call_n_times(count) { }
    end
  end
end

__END__

This attemps to measure the performance of how `routes` works in RSpec. It's
actually a method which delegates to `before`. RSpec executes `before` hooks by
capturing the block and then performing an `instance_exec` on it later in the
example context.

rspec-core has already performed [many related benchmarks about
this](https://github.com/rspec/rspec-core/tree/master/benchmarks):

- [call vs yield](https://github.com/rspec/rspec-core/blob/master/benchmarks/call_v_yield.rb)
- [capture block vs yield](https://github.com/rspec/rspec-core/blob/master/benchmarks/capture_block_vs_yield.rb)
- [flat map vs inject](https://github.com/rspec/rspec-core/blob/master/benchmarks/flat_map_vs_inject.rb)

The results are very interesting:

> This benchmark demonstrates that capturing a block (e.g. `&block`) has
> a high constant cost, taking about 5x longer than a single `yield`
> (even if the block is never used!).
>
> However, fowarding a captured block can be faster than using `yield`
> if the block is used many times (the breakeven point is at about 20-25
> invocations), so it appears that he per-invocation cost of `yield`
> is higher than that of a captured-and-forwarded block.
>
> Note that there is no circumstance where using `block.call` is faster.
>
> See also `flat_map_vs_inject.rb`, which appears to contradict these
> results a little bit.
>
> -- https://github.com/rspec/rspec-core/blob/master/benchmarks/capture_block_vs_yield.rb#L83-L95

and

> Surprisingly, `flat_map(&block)` appears to be faster than
> `flat_map { yield }` in spite of the fact that our array here
> is smaller than the break-even point of 20-25 measured in the
> `capture_block_vs_yield.rb` benchmark. In fact, the forwaded-block
> version remains faster in my benchmarks here no matter how small
> I shrink the `words` array. I'm not sure why!
>
> -- https://github.com/rspec/rspec-core/blob/master/benchmarks/flat_map_vs_inject.rb#L37-L42

This seems to show that the error margin is enough to negate any benefit from
capturing the block initially. It also shows that not capturing the block is
still faster at low rates of calling. If this holds for your system, I think
this PR is good as is and we won't need to capture the block in the `route`
method, but still use `yield`.

My results using Ruby 2.2.0:

Invoking the block 10 times
Calculating -------------------------------------
Yield 10 times
                        13.127k i/100ms
Capture block and yield 10 times
                        12.975k i/100ms
Capture block and call 10 times
                        11.524k i/100ms
-------------------------------------------------
Yield 10 times
                        165.030k (± 5.7%) i/s -    827.001k
Capture block and yield 10 times
                        163.866k (± 5.9%) i/s -    817.425k
Capture block and call 10 times
                        137.892k (± 7.3%) i/s -    691.440k


Invoking the block 25 times
Calculating -------------------------------------
Yield 25 times
                         7.305k i/100ms
Capture block and yield 25 times
                         7.314k i/100ms
Capture block and call 25 times
                         6.047k i/100ms
-------------------------------------------------
Yield 25 times
                         84.167k (± 5.6%) i/s -    423.690k
Capture block and yield 25 times
                         82.110k (± 6.4%) i/s -    409.584k
Capture block and call 25 times
                         67.144k (± 6.2%) i/s -    338.632k


Invoking the block 50 times
Calculating -------------------------------------
Yield 50 times
                         4.211k i/100ms
Capture block and yield 50 times
                         4.181k i/100ms
Capture block and call 50 times
                         3.410k i/100ms
-------------------------------------------------
Yield 50 times
                         45.223k (± 5.0%) i/s -    227.394k
Capture block and yield 50 times
                         45.253k (± 4.9%) i/s -    225.774k
Capture block and call 50 times
                         36.181k (± 5.7%) i/s -    180.730k


Invoking the block 100 times
Calculating -------------------------------------
Yield 100 times
                         2.356k i/100ms
Capture block and yield 100 times
                         2.305k i/100ms
Capture block and call 100 times
                         1.842k i/100ms
-------------------------------------------------
Yield 100 times
                         23.677k (± 7.1%) i/s -    117.800k
Capture block and yield 100 times
                         24.039k (± 4.7%) i/s -    122.165k
Capture block and call 100 times
                         18.888k (± 6.6%) i/s -     95.784k


Invoking the block 1000 times
Calculating -------------------------------------
Yield 1000 times
                       244.000  i/100ms
Capture block and yield 1000 times
                       245.000  i/100ms
Capture block and call 1000 times
                       192.000  i/100ms
-------------------------------------------------
Yield 1000 times
                          2.540k (± 4.3%) i/s -     12.688k
Capture block and yield 1000 times
                          2.499k (± 5.6%) i/s -     12.495k
Capture block and call 1000 times
                          1.975k (± 5.1%) i/s -      9.984k


Invoking the block 10000 times
Calculating -------------------------------------
Yield 10000 times
                        24.000  i/100ms
Capture block and yield 10000 times
                        24.000  i/100ms
Capture block and call 10000 times
                        19.000  i/100ms
-------------------------------------------------
Yield 10000 times
                        232.923  (±15.5%) i/s -      1.128k
Capture block and yield 10000 times
                        212.504  (±21.6%) i/s -    936.000
Capture block and call 10000 times
                        184.090  (±10.3%) i/s -    912.000
