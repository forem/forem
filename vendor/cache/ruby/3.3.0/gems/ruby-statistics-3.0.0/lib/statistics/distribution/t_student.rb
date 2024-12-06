module Statistics
  module Distribution
    class TStudent
      attr_accessor :degrees_of_freedom
      attr_reader :mode

      def initialize(v)
        self.degrees_of_freedom = v
        @mode = 0
      end

      ### Extracted from https://codeplea.com/incomplete-beta-function-c
      ### This function is shared under zlib license and the author is Lewis Van Winkle
      def cumulative_function(value)
        upper = (value + Math.sqrt(value * value + degrees_of_freedom))
        lower = (2.0 * Math.sqrt(value * value + degrees_of_freedom))

        x = upper/lower

        alpha = degrees_of_freedom/2.0
        beta = degrees_of_freedom/2.0

        Math.incomplete_beta_function(x, alpha, beta)
      end

      def density_function(value)
        return if degrees_of_freedom <= 0

        upper = Math.gamma((degrees_of_freedom + 1)/2.0)
        lower = Math.sqrt(degrees_of_freedom * Math::PI) * Math.gamma(degrees_of_freedom/2.0)
        left = upper/lower
        right = (1 + ((value ** 2)/degrees_of_freedom.to_r)) ** -((degrees_of_freedom + 1)/2.0)

        left * right
      end

      def mean
        0 if degrees_of_freedom > 1
      end

      def variance
        if degrees_of_freedom > 1 && degrees_of_freedom <= 2
          Float::INFINITY
        elsif degrees_of_freedom > 2
          degrees_of_freedom/(degrees_of_freedom - 2.0)
        end
      end

      # Quantile function extracted from http://www.jennessent.com/arcview/idf.htm
      # TODO: Make it truly Student's T sample.
      def random(elements: 1, seed: Random.new_seed)
        warn 'This is an alpha version code. The generated sample is similar to an uniform distribution'
        srand(seed)

        v = degrees_of_freedom
        results = []

        # Because the Quantile function of a student-t distribution is between (-Infinity, y)
        # we setup an small threshold in order to properly compute the integral
        threshold = 10_000.0e-12

        elements.times do
          y = rand
          results << Math.simpson_rule(threshold, y, 10_000) do |t|
            up = Math.gamma((v+1)/2.0)
            down = Math.sqrt(Math::PI * v) * Math.gamma(v/2.0)
            right = (1 + ((y ** 2)/v.to_r)) ** ((v+1)/2.0)
            left = up/down.to_r

            left * right
          end
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
