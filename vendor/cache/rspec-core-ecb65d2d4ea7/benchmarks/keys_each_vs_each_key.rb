require 'benchmark/ips'

small_hash = { :key => true, :more_key => true, :other_key => true }
large_hash = (1...100).inject({}) { |hash, key| hash["key_#{key}"] = true; hash }

Benchmark.ips do |x|
  x.report('keys.each with small hash') do
    small_hash.keys.each { |value| value == true }
  end

  x.report('each_key with small hash') do
    small_hash.each_key { |value| value == true }
  end

  x.report('keys.each with large hash') do
    large_hash.keys.each { |value| value == true }
  end

  x.report('each_key with large hash') do
    large_hash.each_key { |value| value == true }
  end
end

__END__

Calculating -------------------------------------
keys.each with small hash
                       105.581k i/100ms
each_key with small hash
                       112.045k i/100ms
keys.each with large hash
                         7.625k i/100ms
each_key with large hash
                         6.959k i/100ms
-------------------------------------------------
keys.each with small hash
                          2.953M (± 3.8%) i/s -     14.781M
each_key with small hash
                          2.917M (± 4.0%) i/s -     14.678M
keys.each with large hash
                         79.349k (± 2.5%) i/s -    396.500k
each_key with large hash
                         72.080k (± 2.1%) i/s -    361.868k
