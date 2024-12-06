module Statistics
  module Distribution
    class Bernoulli
      def self.density_function(n, p)
        return if n != 0 && n != 1 # The support of the distribution is n = {0, 1}.

        case n
        when 0 then 1.0 - p
        when 1 then p
        end
      end

      def self.cumulative_function(n, p)
        return if n != 0 && n != 1 # The support of the distribution is n = {0, 1}.

        case n
        when 0 then 1.0 - p
        when 1 then 1.0
        end
      end

      def self.variance(p)
        p * (1.0 - p)
      end

      def self.skewness(p)
        (1.0 - 2.0*p).to_r / Math.sqrt(p * (1.0 - p))
      end

      def self.kurtosis(p)
        (6.0 * (p ** 2) - (6 * p) + 1) / (p * (1.0 - p))
      end
    end
  end
end
