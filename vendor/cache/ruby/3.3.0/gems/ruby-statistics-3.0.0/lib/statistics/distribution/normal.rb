module Statistics
  module Distribution
    class Normal
      attr_accessor :mean, :standard_deviation, :variance
      alias_method :mode, :mean

      def initialize(avg, std)
        self.mean = avg.to_r
        self.standard_deviation = std.to_r
        self.variance = std.to_r**2
      end

      def cumulative_function(value)
        (1/2.0) * (1.0 + Math.erf((value - mean)/(standard_deviation * Math.sqrt(2.0))))
      end

      def density_function(value)
        return 0 if standard_deviation <= 0

        up_right = (value - mean)**2.0
        down_right = 2.0 * variance
        right = Math.exp(-(up_right/down_right))
        left_down = Math.sqrt(2.0 * Math::PI * variance)
        left_up = 1.0

        (left_up/(left_down) * right)
      end

      ## Marsaglia polar method implementation for random gaussian (normal) number generation.
      # References:
      # https://en.wikipedia.org/wiki/Marsaglia_polar_method
      # https://math.stackexchange.com/questions/69245/transform-uniform-distribution-to-normal-distribution-using-lindeberg-l%C3%A9vy-clt
      # https://www.projectrhea.org/rhea/index.php/The_principles_for_how_to_generate_random_samples_from_a_Gaussian_distribution

      def random(elements: 1, seed: Random.new_seed)
        results = []

        # Setup seed
        srand(seed)

        # Number of random numbers to be generated.
        elements.times do
          x, y, r = 0.0, 0.0, 0.0

          # Find an (x, y) point in the x^2 + y^2 < 1 circumference.
          loop do
            x = 2.0 * rand - 1.0
            y = 2.0 * rand - 1.0

            r = (x ** 2) + (y ** 2)

            break unless r >= 1.0 || r == 0
          end

          # Project the random point to the required random distance
          r = Math.sqrt(-2.0 * Math.log(r) / r)

          # Transform the random distance to a gaussian value and append it to the results array
          results << mean + x * r * standard_deviation
        end

        if elements == 1
          results.first
        else
          results
        end
      end
    end

    class StandardNormal < Normal
      def initialize
        super(0, 1) # Mean = 0, Std = 1
      end

      def density_function(value)
        pow = (value**2)/2.0
        euler = Math.exp(-pow)

        euler/Math.sqrt(2 * Math::PI)
      end
    end

    # Inverse Standard Normal distribution:
    # References:
    # https://en.wikipedia.org/wiki/Inverse_distribution
    # http://www.source-code.biz/snippets/vbasic/9.htm
    class InverseStandardNormal < StandardNormal
      A1 = -39.6968302866538
      A2 = 220.946098424521
      A3 = -275.928510446969
      A4 = 138.357751867269
      A5 = -30.6647980661472
      A6 = 2.50662827745924
      B1 = -54.4760987982241
      B2 = 161.585836858041
      B3 = -155.698979859887
      B4 = 66.8013118877197
      B5 = -13.2806815528857
      C1 = -7.78489400243029E-03
      C2 = -0.322396458041136
      C3 = -2.40075827716184
      C4 = -2.54973253934373
      C5 = 4.37466414146497
      C6 = 2.93816398269878
      D1 = 7.78469570904146E-03
      D2 = 0.32246712907004
      D3 = 2.445134137143
      D4 = 3.75440866190742
      P_LOW = 0.02425
      P_HIGH = 1 - P_LOW

      def density_function(_)
        raise NotImplementedError
      end

      def random(elements: 1, seed: Random.new_seed)
        raise NotImplementedError
      end

      def cumulative_function(value)
        return if value < 0.0 || value > 1.0
        return -1.0 * Float::INFINITY if value.zero?
        return Float::INFINITY if value == 1.0

        if value < P_LOW
          q = Math.sqrt((Math.log(value) * -2.0))
          (((((C1 * q + C2) * q + C3) * q + C4) * q + C5) * q + C6) / ((((D1 * q + D2) * q + D3) * q + D4) * q + 1.0)
        elsif value <= P_HIGH
          q = value - 0.5
          r = q ** 2
          (((((A1 * r + A2) * r + A3) * r + A4) * r + A5) * r + A6) * q / (((((B1 * r + B2) * r + B3) * r + B4) * r + B5) * r + 1.0)
        else
          q = Math.sqrt((Math.log(1 - value) * -2.0))
          - (((((C1 * q + C2) * q + C3) * q + C4) * q + C5) * q + C6) / ((((D1 * q + D2) * q + D3) * q + D4) * q + 1)
        end
      end
    end
  end
end
