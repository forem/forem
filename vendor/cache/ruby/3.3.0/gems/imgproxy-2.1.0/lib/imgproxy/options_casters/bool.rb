module Imgproxy
  module OptionsCasters
    # Casts boolean option
    module Bool
      def self.cast(raw)
        return if raw.nil?

        raw && raw != 0 && raw != "0" ? 1 : 0
      end
    end
  end
end
