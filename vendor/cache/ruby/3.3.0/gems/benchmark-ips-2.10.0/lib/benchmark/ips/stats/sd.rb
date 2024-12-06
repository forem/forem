module Benchmark
  module IPS
    module Stats

      class SD
        include StatsMetric
        attr_reader :error, :samples

        def initialize(samples)
          @samples = samples
          @mean = Timing.mean(samples)
          @error = Timing.stddev(samples, @mean).round
        end

        # Average stat value
        # @return [Float] central_tendency
        def central_tendency
          @mean
        end

        # Determines how much slower this stat is than the baseline stat
        # if this average is lower than the faster baseline, higher average is better (e.g. ips) (calculate accordingly)
        # @param baseline [SD|Bootstrap] faster baseline
        # @returns [Array<Float, nil>] the slowdown and the error (not calculated for standard deviation)
        def slowdown(baseline)
          if baseline.central_tendency > central_tendency
            [baseline.central_tendency.to_f / central_tendency, 0]
          else
            [central_tendency.to_f / baseline.central_tendency, 0]
          end
        end

        def speedup(baseline)
          baseline.slowdown(self)
        end

        def footer
          nil
        end

      end

    end
  end
end
