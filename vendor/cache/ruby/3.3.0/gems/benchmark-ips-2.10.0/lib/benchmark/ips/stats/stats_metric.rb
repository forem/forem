module Benchmark
  module IPS
    module Stats
      module StatsMetric
        # Return entry's standard deviation of iteration per second in percentage.
        # @return [Float] +@ips_sd+ in percentage.
        def error_percentage
          100.0 * (error.to_f / central_tendency)
        end

        def overlaps?(baseline)
          baseline_low = baseline.central_tendency - baseline.error
          baseline_high = baseline.central_tendency + baseline.error
          my_high = central_tendency + error
          my_low  = central_tendency - error
          my_high > baseline_low && my_low < baseline_high
        end
      end
    end
  end
end
