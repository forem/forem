module Statistics
  module Distribution
    class Empirical
      attr_accessor :samples

      def initialize(samples:)
        self.samples = samples
      end

      # Formula grabbed from here: https://statlect.com/asymptotic-theory/empirical-distribution
      def cumulative_function(x:)
        cumulative_sum = samples.reduce(0) do |summation, sample|
          summation += if sample <= x
                         1
                       else
                         0
                       end

          summation
        end

        cumulative_sum / samples.size.to_r
      end
    end
  end
end
