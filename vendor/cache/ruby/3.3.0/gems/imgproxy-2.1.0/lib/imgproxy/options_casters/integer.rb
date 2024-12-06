module Imgproxy
  module OptionsCasters
    # Casts integer option
    module Integer
      def self.cast(raw)
        raw&.to_i
      end
    end
  end
end
