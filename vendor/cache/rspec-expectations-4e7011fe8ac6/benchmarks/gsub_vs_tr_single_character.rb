require 'benchmark/ips'

Benchmark.ips do |x|
  y = '1_2_3_4_5_6_7_8_9_10'

  x.report('gsub') do |_times|
    y.tr('_', ' ')
  end

  x.report('tr') do |_times|
    y.tr('_', ' ')
  end

  x.compare!
end

__END__

Calculating -------------------------------------
                gsub    29.483k i/100ms
                  tr    79.170k i/100ms
-------------------------------------------------
                gsub     10.420B (±23.7%) i/s -     31.106B
                  tr     78.139B (±20.6%) i/s -    129.289B

Comparison:
                  tr: 78139428607.9 i/s
                gsub: 10419757735.7 i/s - 7.50x slower
