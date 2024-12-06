module Statistics
  module Distribution
    class Weibull
      attr_accessor :shape, :scale # k and lambda

      def initialize(k, lamb)
        self.shape = k.to_r
        self.scale = lamb.to_r
      end

      def cumulative_function(random_value)
        return 0 if random_value < 0

        1 - Math.exp(-((random_value/scale) ** shape))
      end

      def density_function(value)
        return if shape <= 0 || scale <= 0
        return 0 if value < 0

        left = shape/scale
        center = (value/scale)**(shape - 1)
        right = Math.exp(-((value/scale)**shape))

        left * center * right
      end

      def mean
        scale * Math.gamma(1 + (1/shape))
      end

      def mode
        return 0 if shape <= 1

        scale * (((shape - 1)/shape) ** (1/shape))
      end

      def variance
        left = Math.gamma(1 + (2/shape))
        right = Math.gamma(1 + (1/shape)) ** 2

        (scale ** 2) * (left - right)
      end

      # Using the inverse CDF function, also called quantile, we can calculate
      # a random sample that follows a weibull distribution.
      #
      # Formula extracted from https://www.taygeta.com/random/weibull.html
      def random(elements: 1, seed: Random.new_seed)
        results = []

        srand(seed)

        elements.times do
          results << ((-1/scale) * Math.log(1 - rand)) ** (1/shape)
        end

        if elements == 1
          results.first
        else
          results
        end
      end
    end
  end
end
