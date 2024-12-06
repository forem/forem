module Statistics
  module Distribution
    class Beta
      attr_accessor :alpha, :beta

      def initialize(alp, bet)
        self.alpha = alp.to_r
        self.beta = bet.to_r
      end

      def cumulative_function(value)
        Math.incomplete_beta_function(value, alpha, beta)
      end

      def density_function(value)
        return 0 if value < 0 || value > 1 # Density function defined in the [0,1] interval

        num = (value**(alpha - 1)) * ((1 - value)**(beta - 1))
        den = Math.beta_function(alpha, beta)

        num/den
      end

      def mode
        return unless alpha > 1 && beta > 1

        (alpha - 1)/(alpha + beta - 2)
      end

      def mean
        return if alpha + beta == 0
        alpha / (alpha + beta)
      end
    end
  end
end
