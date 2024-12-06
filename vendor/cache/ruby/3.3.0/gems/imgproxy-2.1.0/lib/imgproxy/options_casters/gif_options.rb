require "imgproxy/options_casters/group"
require "imgproxy/options_casters/bool"

module Imgproxy
  module OptionsCasters
    # Casts gif_options option
    module GifOptions
      CASTER = Imgproxy::OptionsCasters::Group.new(
        optimize_frames: Imgproxy::OptionsCasters::Bool,
        optimize_transparency: Imgproxy::OptionsCasters::Bool,
      ).freeze

      def self.cast(raw)
        return raw unless raw.is_a?(Hash)

        values = CASTER.cast(raw)
        values.empty? ? nil : values
      end
    end
  end
end
