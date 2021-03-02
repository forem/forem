require 'benchmark/ips'

def create_stack_trace(n, &block)
  return create_stack_trace(n - 1, &block) if n > 0
  yield
end

[10, 50, 100].each do |frames|
  create_stack_trace(frames) do
    Benchmark.ips do |x|
      x.report("use caller (#{caller.count} frames)") do
        exception = RuntimeError.new("boom")
        exception.set_backtrace caller
        exception.backtrace
      end

      x.report("use raise (#{caller.count} frames)") do
        exception = begin
          raise "boom"
        rescue => e
          e
        end

        exception.backtrace
      end

      x.compare!
    end
  end
end

__END__

Calculating -------------------------------------
use caller (16 frames)
                         4.986k i/100ms
use raise (16 frames)
                         4.255k i/100ms
-------------------------------------------------
use caller (16 frames)
                         52.927k (± 9.9%) i/s -    264.258k
use raise (16 frames)
                         50.079k (±10.1%) i/s -    251.045k

Comparison:
use caller (16 frames):    52927.3 i/s
use raise (16 frames):    50078.6 i/s - 1.06x slower

Calculating -------------------------------------
use caller (56 frames)
                         2.145k i/100ms
use raise (56 frames)
                         2.065k i/100ms
-------------------------------------------------
use caller (56 frames)
                         22.282k (± 9.3%) i/s -    111.540k
use raise (56 frames)
                         21.428k (± 9.9%) i/s -    107.380k

Comparison:
use caller (56 frames):    22281.5 i/s
use raise (56 frames):    21428.1 i/s - 1.04x slower

Calculating -------------------------------------
use caller (106 frames)
                         1.284k i/100ms
use raise (106 frames)
                         1.253k i/100ms
-------------------------------------------------
use caller (106 frames)
                         12.437k (±10.6%) i/s -     62.916k
use raise (106 frames)
                         10.873k (±12.6%) i/s -     53.879k

Comparison:
use caller (106 frames):    12437.4 i/s
use raise (106 frames):    10873.2 i/s - 1.14x slower
