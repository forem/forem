module Statistics
  module Distribution
    class Uniform
      attr_accessor :left, :right

      def initialize(a, b)
        self.left = a.to_r
        self.right = b.to_r
      end

      def density_function(value)
        if value >= left && value <= right
          1/(right - left)
        else
          0
        end
      end

      def cumulative_function(value)
        if value < left
          0
        elsif value >= left && value <= right
          (value - left)/(right - left)
        else
          1
        end
      end

      def mean
        (1/2.0) * ( left + right )
      end
      alias_method :median, :mean


      def variance
        (1/12.0) * ( right - left ) ** 2
      end
    end
  end
end
