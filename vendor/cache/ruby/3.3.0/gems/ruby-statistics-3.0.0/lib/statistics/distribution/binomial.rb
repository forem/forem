module Statistics
  module Distribution
    class Binomial
      attr_accessor :number_of_trials, :probability_per_trial
      def initialize(n, p)
        self.number_of_trials = n.to_i
        self.probability_per_trial = p
      end

      def probability_mass_function(k)
        return if k < 0 || k > number_of_trials
        k = k.to_i

        Math.combination(number_of_trials, k) *
          (probability_per_trial ** k) * ((1 - probability_per_trial) ** (number_of_trials - k))
      end

      def cumulative_function(k)
        return if k < 0 || k > number_of_trials
        k = k.to_i

        p = 1 - probability_per_trial
        Math.incomplete_beta_function(p, number_of_trials - k, 1 + k)
      end

      def mean
        number_of_trials * probability_per_trial
      end

      def variance
        mean * (1 - probability_per_trial)
      end

      def mode
        test = (number_of_trials + 1) * probability_per_trial

        returned = if test == 0 || (test % 1 != 0)
                     test.floor
                   elsif (test % 1 == 0)  && (test >= 1 && test <= number_of_trials)
                     [test, test - 1]
                   elsif test == number_of_trials + 1
                     number_of_trials
                   end

        returned
      end
    end
  end
end
