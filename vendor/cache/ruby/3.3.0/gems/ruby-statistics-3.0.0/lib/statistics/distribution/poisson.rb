module Statistics
  module Distribution
    class Poisson
      attr_accessor :expected_number_of_occurrences

      alias_method :mean, :expected_number_of_occurrences
      alias_method :variance, :expected_number_of_occurrences

      def initialize(l)
        self.expected_number_of_occurrences = l
      end

      def probability_mass_function(k)
        return if k < 0 || expected_number_of_occurrences < 0

        k = k.to_i

        upper = (expected_number_of_occurrences ** k) * Math.exp(-expected_number_of_occurrences)
        lower = Math.factorial(k)

        upper/lower.to_r
      end

      def cumulative_function(k)
        return if k < 0 || expected_number_of_occurrences < 0

        k = k.to_i

        upper = Math.lower_incomplete_gamma_function((k + 1).floor, expected_number_of_occurrences)
        lower = Math.factorial(k.floor)

        # We need the right tail, i.e.: The upper incomplete gamma function. This can be
        # achieved by doing a substraction between 1 and the lower incomplete gamma function.
        1 - (upper/lower.to_r)
      end
    end
  end
end
