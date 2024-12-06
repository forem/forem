require "imgproxy/options_casters/group"
require "imgproxy/options_casters/bool"
require "imgproxy/options_casters/gravity"

module Imgproxy
  module OptionsCasters
    # Casts extend option
    module Extend
      CASTER = Imgproxy::OptionsCasters::Group.new(
        extend: Imgproxy::OptionsCasters::Bool,
        gravity: Imgproxy::OptionsCasters::Gravity,
      ).freeze

      def self.cast(raw)
        # Allow extend to be just a boolean
        return Imgproxy::OptionsCasters::Bool.cast(raw) if [true, false].include?(raw)

        return raw unless raw.is_a?(Hash)
        return if raw[:extend].nil?

        values = CASTER.cast(raw)
        values[0].zero? ? 0 : values
      end
    end
  end
end
