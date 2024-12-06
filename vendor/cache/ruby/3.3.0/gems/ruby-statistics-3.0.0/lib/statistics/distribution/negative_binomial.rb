module Statistics
  module Distribution
    class NegativeBinomial
      attr_accessor :number_of_failures, :probability_per_trial

      def initialize(r, p)
        self.number_of_failures = r.to_i
        self.probability_per_trial = p
      end

      def probability_mass_function(k)
        return if number_of_failures < 0 || k < 0 || k > number_of_failures

        left = Math.combination(k + number_of_failures - 1, k)
        right = ((1 - probability_per_trial) ** number_of_failures) * (probability_per_trial ** k)

        left * right
      end

      def cumulative_function(k)
        return if k < 0 || k > number_of_failures
        k = k.to_i

        1.0 - Math.incomplete_beta_function(probability_per_trial, k + 1, number_of_failures)
      end

      def mean
        (probability_per_trial * number_of_failures)/(1 - probability_per_trial).to_r
      end

      def variance
        (probability_per_trial * number_of_failures)/((1 - probability_per_trial) ** 2).to_r
      end

      def skewness
        (1 + probability_per_trial).to_r / Math.sqrt(probability_per_trial * number_of_failures)
      end

      def mode
        if number_of_failures > 1
          up = probability_per_trial * (number_of_failures - 1)
          down = (1 - probability_per_trial).to_r

          (up/down).floor
        elsif number_of_failures <= 1
          0.0
        end
      end
    end
  end
end
