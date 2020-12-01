require 'benchmark'

n = 100_000

def call_block(&block)
  block.call
end

def yield_control
  yield
end

Benchmark.benchmark do |bm|
  puts "#{n} times - ruby #{RUBY_VERSION}"

  puts
  puts "eval"

  3.times do
    bm.report do
      n.times do
        eval("2 + 3")
      end
    end
  end

  puts
  puts "call block"

  3.times do
    bm.report do
      n.times do
        call_block { 2 + 3 }
      end
    end
  end

  puts
  puts "yield"

  3.times do
    bm.report do
      n.times do
        yield_control { 2 + 3 }
      end
    end
  end

  puts
  puts "exec"

  3.times do
    bm.report do
      n.times do
        2 + 3
      end
    end
  end
end

# 100000 times - ruby 1.9.3
#
# eval
#    0.870000   0.010000   0.880000 (  0.877762)
#    0.890000   0.000000   0.890000 (  0.891142)
#    0.890000   0.000000   0.890000 (  0.896365)
#
# call block
#    0.120000   0.010000   0.130000 (  0.136322)
#    0.130000   0.010000   0.140000 (  0.138608)
#    0.130000   0.000000   0.130000 (  0.129931)
#
# yield
#    0.020000   0.000000   0.020000 (  0.020412)
#    0.010000   0.000000   0.010000 (  0.017926)
#    0.020000   0.000000   0.020000 (  0.025740)
#
# exec
#    0.010000   0.000000   0.010000 (  0.009935)
#    0.010000   0.000000   0.010000 (  0.011588)
#    0.010000   0.000000   0.010000 (  0.010613)
