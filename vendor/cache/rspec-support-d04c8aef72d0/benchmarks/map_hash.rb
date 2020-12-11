require 'benchmark/ips'

def use_map_and_hash_bracket(input)
  Hash[ input.map { |k, v| [k.to_s, v.to_s] } ]
end

def use_inject(input)
  input.inject({}) do |hash, (k, v)|
    hash[k.to_s] = v.to_s
    hash
  end
end

[10, 100, 1000].each do |size|
  hash = Hash[1.upto(size).map { |i| [i, i] }]
  unless use_map_and_hash_bracket(hash) == use_inject(hash)
    raise "Not the same!"
  end

  puts
  puts "A hash of #{size} pairs"

  Benchmark.ips do |x|
    x.report("Use map and Hash[]") { use_map_and_hash_bracket(hash) }
    x.report("Use inject") { use_inject(hash) }
    x.compare!
  end
end

__END__

`inject` appears to be slightly faster.

A hash of 10 pairs
Calculating -------------------------------------
  Use map and Hash[]     8.742k i/100ms
          Use inject     9.565k i/100ms
-------------------------------------------------
  Use map and Hash[]     98.220k (± 6.8%) i/s -    489.552k
          Use inject    110.130k (± 6.1%) i/s -    554.770k

Comparison:
          Use inject:   110129.9 i/s
  Use map and Hash[]:    98219.8 i/s - 1.12x slower


A hash of 100 pairs
Calculating -------------------------------------
  Use map and Hash[]     1.080k i/100ms
          Use inject     1.124k i/100ms
-------------------------------------------------
  Use map and Hash[]     10.931k (± 4.5%) i/s -     55.080k
          Use inject     11.494k (± 5.0%) i/s -     57.324k

Comparison:
          Use inject:    11494.4 i/s
  Use map and Hash[]:    10930.7 i/s - 1.05x slower


A hash of 1000 pairs
Calculating -------------------------------------
  Use map and Hash[]   106.000  i/100ms
          Use inject   111.000  i/100ms
-------------------------------------------------
  Use map and Hash[]      1.081k (± 5.1%) i/s -      5.406k
          Use inject      1.111k (± 4.8%) i/s -      5.550k

Comparison:
          Use inject:     1111.2 i/s
  Use map and Hash[]:     1080.8 i/s - 1.03x slower
