require 'benchmark/ips'

[10, 100, 1000, 10_000, 100_000].each do |array_size|
  array = (1..array_size).to_a

  Benchmark.ips do |ips|
    ips.report("#select { true }.size for #{array_size}") do
      array.select { true }.size
    end
    ips.report("#count { true } for #{array_size}") do
      array.count { true }
    end
  end
end

__END__

ruby benchmarks/count_vs_select_size.rb                                                                                                                                                                                        (git)-[main]
Warming up --------------------------------------
#select { true }.size for 10
                       129.033k i/100ms
#count { true } for 10
                       168.627k i/100ms
Calculating -------------------------------------
#select { true }.size for 10
                          1.397M (± 6.8%) i/s -      6.968M in   5.011533s
#count { true } for 10
                          1.716M (± 7.8%) i/s -      8.600M in   5.048212s
Warming up --------------------------------------
#select { true }.size for 100
                        16.633k i/100ms
#count { true } for 100
                        19.215k i/100ms
Calculating -------------------------------------
#select { true }.size for 100
                        170.209k (± 8.1%) i/s -    848.283k in   5.036749s
#count { true } for 100
                        212.102k (± 4.1%) i/s -      1.076M in   5.081653s
Warming up --------------------------------------
#select { true }.size for 1000
                         1.650k i/100ms
#count { true } for 1000
                         1.803k i/100ms
Calculating -------------------------------------
#select { true }.size for 1000
                         15.651k (±17.0%) i/s -     75.900k in   5.073128s
#count { true } for 1000
                         20.613k (± 5.6%) i/s -    104.574k in   5.091257s
Warming up --------------------------------------
#select { true }.size for 10000
                       146.000  i/100ms
#count { true } for 10000
                       202.000  i/100ms
Calculating -------------------------------------
#select { true }.size for 10000
                          1.613k (± 8.4%) i/s -      8.030k in   5.014577s
#count { true } for 10000
                          2.031k (± 4.8%) i/s -     10.302k in   5.085695s
Warming up --------------------------------------
#select { true }.size for 100000
                        15.000  i/100ms
#count { true } for 100000
                        21.000  i/100ms
Calculating -------------------------------------
#select { true }.size for 100000
                        170.963  (± 4.1%) i/s -    855.000  in   5.010050s
#count { true } for 100000
                        211.185  (± 4.7%) i/s -      1.071k in   5.083109s
