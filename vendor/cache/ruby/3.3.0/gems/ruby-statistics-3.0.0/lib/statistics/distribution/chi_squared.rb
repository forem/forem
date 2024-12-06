module Statistics
  module Distribution
    class ChiSquared
      attr_accessor :degrees_of_freedom

      alias_method :mean, :degrees_of_freedom

      def initialize(k)
        self.degrees_of_freedom = k
      end

      def cumulative_function(value)
        k = degrees_of_freedom/2.0
        Math.lower_incomplete_gamma_function(k, value/2.0)/Math.gamma(k)
      end

      def density_function(value)
        return 0 if value < 0

        common = degrees_of_freedom/2.0

        left_down = (2 ** common) * Math.gamma(common)
        right = (value ** (common - 1)) * Math.exp(-(value/2.0))

        (1.0/left_down) * right
      end

      def mode
        [degrees_of_freedom - 2, 0].max
      end

      def variance
        degrees_of_freedom * 2
      end
    end
  end
end
