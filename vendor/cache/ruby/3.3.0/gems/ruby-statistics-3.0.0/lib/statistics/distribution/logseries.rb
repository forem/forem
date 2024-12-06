module Statistics
  module Distribution
    class LogSeries
      def self.density_function(k, p)
        return if k <= 0
        k = k.to_i

        left = (-1.0 / Math.log(1.0 - p))
        right = (p ** k).to_r

        left * right / k
      end

      def self.cumulative_function(k, p)
        return if k <= 0

        # Sadly, the incomplete beta function is converging
        # too fast to zero and breaking the calculation on logs.
        # So, we default to the basic definition of the CDF which is
        # the integral (-Inf, K) of the PDF, with P(X <= x) which can
        # be solved as a summation of all PDFs from 1 to K. Note that the summation approach
        # only applies to discrete distributions.
        #
        # right = Math.incomplete_beta_function(p, (k + 1).floor, 0) / Math.log(1.0 - p)
        # 1.0 + right

        result = 0.0
        1.upto(k) do |number|
          result += self.density_function(number, p)
        end

        result
      end

      def self.mode
        1.0
      end

      def self.mean(p)
        (-1.0 / Math.log(1.0 - p)) * (p / (1.0 - p))
      end

      def self.variance(p)
        up = p + Math.log(1.0 - p)
        down = ((1.0 - p) ** 2) * (Math.log(1.0 - p) ** 2)

        (-1.0 * p) * (up / down.to_r)
      end
    end
  end
end
