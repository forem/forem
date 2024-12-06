module Imgproxy
  module OptionsCasters
    # Casts string option
    module String
      def self.cast(raw)
        raw&.to_s
      end
    end
  end
end
