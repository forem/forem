module Imgproxy
  module OptionsCasters
    # Casts array option
    module Array
      def self.cast(raw)
        return if raw.nil?

        raw.is_a?(Array) ? raw : [raw]
      end
    end
  end
end
