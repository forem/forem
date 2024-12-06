require 'flipper/typecast'

module Flipper
  module Types
    class Percentage < Type
      def initialize(value)
        value = Typecast.to_percentage(value)

        if value < 0 || value > 100
          raise ArgumentError,
                "value must be a positive number less than or equal to 100, but was #{value}"
        end

        @value = value
      end
    end
  end
end
