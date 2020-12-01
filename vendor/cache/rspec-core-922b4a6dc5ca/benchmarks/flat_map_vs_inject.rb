require 'benchmark/ips'

words = %w[ foo bar bazz big small medium large tiny less more good bad mediocre ]

def flat_map_using_yield(array)
  array.flat_map { |item| yield item }
end

def flat_map_using_block(array, &block)
  array.flat_map(&block)
end

Benchmark.ips do |x|
  x.report("flat_map") do
    words.flat_map(&:codepoints)
  end

  x.report("inject (+)") do
    words.inject([]) { |a, w| a + w.codepoints }
  end

  x.report("inject (concat)") do
    words.inject([]) { |a, w| a.concat w.codepoints }
  end

  x.report("flat_map_using_yield") do
    flat_map_using_yield(words, &:codepoints)
  end

  x.report("flat_map_using_block") do
    flat_map_using_block(words, &:codepoints)
  end
end

__END__

Surprisingly, `flat_map(&block)` appears to be faster than
`flat_map { yield }` in spite of the fact that our array here
is smaller than the break-even point of 20-25 measured in the
`capture_block_vs_yield.rb` benchmark. In fact, the forwaded-block
version remains faster in my benchmarks here no matter how small
I shrink the `words` array. I'm not sure why!

Calculating -------------------------------------
            flat_map    10.594k i/100ms
          inject (+)     8.357k i/100ms
     inject (concat)    10.404k i/100ms
flat_map_using_yield    10.081k i/100ms
flat_map_using_block    11.683k i/100ms
-------------------------------------------------
            flat_map    136.442k (±10.4%) i/s -    678.016k
          inject (+)     98.024k (± 9.7%) i/s -    493.063k
     inject (concat)    119.822k (±10.5%) i/s -    593.028k
flat_map_using_yield    112.284k (± 9.7%) i/s -    564.536k
flat_map_using_block    134.533k (± 6.3%) i/s -    677.614k
