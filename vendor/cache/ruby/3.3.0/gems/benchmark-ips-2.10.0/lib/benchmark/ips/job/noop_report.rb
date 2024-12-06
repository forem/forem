module Benchmark
  module IPS
    class Job
      class NoopReport
        def start_warming
        end

        def start_running
        end

        def footer
        end

        def warming(a, b)
        end

        def warmup_stats(a, b)
        end

        def add_report(a, b)
        end

        alias_method :running, :warming
      end
    end
  end
end
