require "imgproxy/options_casters/group"
require "imgproxy/options_casters/bool"
require "imgproxy/options_casters/integer"

module Imgproxy
  module OptionsCasters
    # Casts png_options option
    module PngOptions
      CASTER = Imgproxy::OptionsCasters::Group.new(
        interlaced: Imgproxy::OptionsCasters::Bool,
        quantize: Imgproxy::OptionsCasters::Bool,
        quantization_colors: Imgproxy::OptionsCasters::Integer,
      ).freeze

      def self.cast(raw)
        return raw unless raw.is_a?(Hash)

        values = CASTER.cast(raw)
        values.empty? ? nil : values
      end
    end
  end
end
