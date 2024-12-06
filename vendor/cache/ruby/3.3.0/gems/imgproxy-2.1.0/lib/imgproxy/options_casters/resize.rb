require "imgproxy/trim_array"
require "imgproxy/options_casters/string"
require "imgproxy/options_casters/size"

module Imgproxy
  module OptionsCasters
    # Casts resize option
    module Resize
      using TrimArray

      def self.cast(raw)
        return raw unless raw.is_a?(Hash)

        [
          Imgproxy::OptionsCasters::String.cast(raw[:resizing_type]) || "fit",
          *Imgproxy::OptionsCasters::Size.cast(raw),
        ].trim!
      end
    end
  end
end
