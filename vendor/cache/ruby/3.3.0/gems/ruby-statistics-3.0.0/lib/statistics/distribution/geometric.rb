module Statistics
  module Distribution
    class Geometric
      attr_accessor :probability_of_success, :always_success_allowed

      def initialize(p, always_success: false)
        self.probability_of_success = p.to_r
        self.always_success_allowed = always_success
      end

      def density_function(k)
        k = k.to_i

        if always_success_allowed
          return if k < 0

          ((1.0 - probability_of_success) ** k) * probability_of_success
        else
          return if k <= 0

          ((1.0 - probability_of_success) ** (k - 1.0)) * probability_of_success
        end
      end

      def cumulative_function(k)
        k = k.to_i

        if always_success_allowed
          return if k < 0

          1.0 - ((1.0 - probability_of_success) ** (k + 1.0))
        else
          return if k <= 0

          1.0 - ((1.0 - probability_of_success) ** k)
        end
      end

      def mean
        if always_success_allowed
          (1.0 - probability_of_success) / probability_of_success
        else
          1.0 / probability_of_success
        end
      end

      def median
        if always_success_allowed
          (-1.0 / Math.log2(1.0 - probability_of_success)).ceil - 1.0
        else
          (-1.0 / Math.log2(1.0 - probability_of_success)).ceil
        end
      end

      def mode
        if always_success_allowed
          0.0
        else
          1.0
        end
      end

      def variance
        (1.0 - probability_of_success) / (probability_of_success ** 2)
      end

      def skewness
        (2.0 - probability_of_success) / Math.sqrt(1.0 - probability_of_success)
      end

      def kurtosis
        6.0 + ((probability_of_success ** 2) / (1.0 - probability_of_success))
      end
    end
  end
end
