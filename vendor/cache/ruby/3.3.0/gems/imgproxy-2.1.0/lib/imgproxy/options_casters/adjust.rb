require "imgproxy/options_casters/group"
require "imgproxy/options_casters/integer"
require "imgproxy/options_casters/float"

module Imgproxy
  module OptionsCasters
    # Casts gravity option
    module Adjust
      CASTER = Imgproxy::OptionsCasters::Group.new(
        brightness: Imgproxy::OptionsCasters::Integer,
        contrast: Imgproxy::OptionsCasters::Float,
        saturation: Imgproxy::OptionsCasters::Float,
      ).freeze

      def self.cast(raw)
        return raw unless raw.is_a?(Hash)

        CASTER.cast(raw)
      end
    end
  end
end
