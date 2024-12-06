module Statistics
  module Distribution
    class F
      attr_accessor :d1, :d2 # Degrees of freedom #1 and #2

      def initialize(k, j)
        self.d1 = k
        self.d2 = j
      end

      # Formula extracted from http://www.itl.nist.gov/div898/handbook/eda/section3/eda3665.htm#CDF
      def cumulative_function(value)
        k = d2/(d2 + d1 * value.to_r)

        1 - Math.incomplete_beta_function(k, d2/2.0, d1/2.0)
      end

      def density_function(value)
        return if d1 < 0 || d2 < 0 # F-pdf is well defined for the [0, +infinity) interval.

        val = value.to_r
        upper = ((d1 * val) ** d1) * (d2**d2)
        lower = (d1 * val + d2) ** (d1 + d2)
        up = Math.sqrt(upper/lower.to_r)
        down = val * Math.beta_function(d1/2.0, d2/2.0)

        up/down.to_r
      end

      def mean
        return if d2 <= 2

        d2/(d2 - 2).to_r
      end

      def mode
        return if d1 <= 2

        left = (d1 - 2)/d1.to_r
        right = d2/(d2 + 2).to_r

        (left * right).to_f
      end
    end
  end
end
