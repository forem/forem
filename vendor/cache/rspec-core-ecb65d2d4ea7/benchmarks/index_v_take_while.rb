require 'benchmark'

n = 10000

list = 1.upto(10).to_a

Benchmark.benchmark do |bm|
  puts "take_while"
  3.times do
    bm.report do
      n.times do
        list.
          take_while {|i| i < 6}.
          map {|i| i}.
          compact
      end
    end
  end

  puts

  puts "list[0,n]"
  3.times do
    bm.report do
      n.times do
        if index = list.index(6)
          list[0, index].map {|i| i.to_s}
        else
          list.map {|i| i}.compact
        end
      end
    end
  end
end

__END__

ruby benchmarks/index_v_take_while.rb
take_while
   0.020000   0.000000   0.020000 (  0.020005)
   0.010000   0.000000   0.010000 (  0.015907)
   0.010000   0.000000   0.010000 (  0.015962)

list[0,n]
   0.020000   0.000000   0.020000 (  0.023561)
   0.020000   0.000000   0.020000 (  0.018812)
   0.030000   0.000000   0.030000 (  0.022389)
