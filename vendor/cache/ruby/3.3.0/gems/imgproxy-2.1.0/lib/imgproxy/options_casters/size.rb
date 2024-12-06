require "imgproxy/trim_array"
require "imgproxy/options_casters/integer"
require "imgproxy/options_casters/bool"
require "imgproxy/options_casters/extend"

module Imgproxy
  module OptionsCasters
    # Casts size option
    module Size
      using TrimArray

      def self.cast(raw)
        return raw unless raw.is_a?(Hash)

        [
          Imgproxy::OptionsCasters::Integer.cast(raw[:width]) || 0,
          Imgproxy::OptionsCasters::Integer.cast(raw[:height]) || 0,
          Imgproxy::OptionsCasters::Bool.cast(raw[:enlarge]),
          Imgproxy::OptionsCasters::Extend.cast(raw[:extend]),
        ].trim!
      end
    end
  end
end
