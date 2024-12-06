require "imgproxy/options_casters/group"
require "imgproxy/options_casters/string"
require "imgproxy/options_casters/float"

module Imgproxy
  module OptionsCasters
    # Casts gravity option
    module Gravity
      CASTER = Imgproxy::OptionsCasters::Group.new(
        type: Imgproxy::OptionsCasters::String,
        x_offset: Imgproxy::OptionsCasters::Float,
        y_offset: Imgproxy::OptionsCasters::Float,
      ).freeze

      def self.cast(raw)
        return raw unless raw.is_a?(Hash)
        return unless raw[:type]

        CASTER.cast(raw)
      end
    end
  end
end
