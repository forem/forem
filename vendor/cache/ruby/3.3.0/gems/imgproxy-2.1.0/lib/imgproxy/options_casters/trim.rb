require "imgproxy/options_casters/group"
require "imgproxy/options_casters/float"
require "imgproxy/options_casters/string"
require "imgproxy/options_casters/bool"

module Imgproxy
  module OptionsCasters
    # Casts trim option
    module Trim
      CASTER = Imgproxy::OptionsCasters::Group.new(
        threshold: Imgproxy::OptionsCasters::Float,
        color: Imgproxy::OptionsCasters::String,
        equal_hor: Imgproxy::OptionsCasters::Bool,
        equal_ver: Imgproxy::OptionsCasters::Bool,
      ).freeze

      def self.cast(raw)
        # Allow trim to be just a numeric
        return Imgproxy::OptionsCasters::Float.cast(raw) if raw.is_a?(Numeric)

        return raw unless raw.is_a?(Hash)
        return unless raw[:threshold]

        CASTER.cast(raw)
      end
    end
  end
end
