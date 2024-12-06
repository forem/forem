require "imgproxy/trim_array"
require "imgproxy/options_casters/float"
require "imgproxy/options_casters/gravity"

module Imgproxy
  module OptionsCasters
    # Casts crop option
    module Crop
      using TrimArray

      def self.cast(raw)
        return raw unless raw.is_a?(Hash)
        return unless raw[:width] || raw[:height]

        [
          Imgproxy::OptionsCasters::Float.cast(raw[:width]) || 0,
          Imgproxy::OptionsCasters::Float.cast(raw[:height]) || 0,
          Imgproxy::OptionsCasters::Gravity.cast(raw[:gravity]),
        ].trim!
      end
    end
  end
end
