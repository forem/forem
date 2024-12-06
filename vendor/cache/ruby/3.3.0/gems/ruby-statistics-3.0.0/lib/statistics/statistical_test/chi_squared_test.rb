module Statistics
  module StatisticalTest
    class ChiSquaredTest
      def self.chi_statistic(expected, observed)
        # If the expected is a number, we asumme that all expected observations
        # has the same probability to occur, hence we expect to see the same number
        # of expected observations per each observed value
        statistic = if expected.is_a? Numeric
                      observed.reduce(0) do |memo, observed_value|
                        up = (observed_value - expected) ** 2
                        memo += (up/expected.to_r)
                      end
                    else
                      expected.each_with_index.reduce(0) do |memo, (expected_value, index)|
                        up = (observed[index] - expected_value) ** 2
                        memo += (up/expected_value.to_r)
                      end
                    end

          [statistic, observed.size - 1]
      end

      def self.goodness_of_fit(alpha, expected, observed)
        chi_score, df = *self.chi_statistic(expected, observed) # Splat array result

        return if chi_score.nil? || df.nil?

        probability = Distribution::ChiSquared.new(df).cumulative_function(chi_score)
        p_value = 1 - probability

        # According to https://stats.stackexchange.com/questions/29158/do-you-reject-the-null-hypothesis-when-p-alpha-or-p-leq-alpha
        # We can assume that if p_value <= alpha, we can safely reject the null hypothesis, ie. accept the alternative hypothesis.
        { probability: probability,
          p_value: p_value,
          alpha: alpha,
          null: alpha < p_value,
          alternative: p_value <= alpha,
          confidence_level: 1 - alpha }
      end
    end
  end
end
