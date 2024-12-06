module Imgproxy
  module OptionsCasters
    # Casts float option
    module Float
      ZERO_RE = /\.0+/.freeze

      def self.cast(raw)
        raw&.to_f&.then do |f|
          # Convert integral value to Integer so to_s won't give us trailing zero
          i = f.to_i
          i == f ? i : f
        end
      end
    end
  end
end
