require "imgproxy/options_casters/group"
require "imgproxy/options_casters/bool"
require "imgproxy/options_casters/integer"

module Imgproxy
  module OptionsCasters
    # Casts jpeg_options option
    module JpegOptions
      CASTER = Imgproxy::OptionsCasters::Group.new(
        progressive: Imgproxy::OptionsCasters::Bool,
        no_subsample: Imgproxy::OptionsCasters::Bool,
        trellis_quant: Imgproxy::OptionsCasters::Bool,
        overshoot_deringing: Imgproxy::OptionsCasters::Bool,
        optimize_scans: Imgproxy::OptionsCasters::Bool,
        quant_table: Imgproxy::OptionsCasters::Integer,
      ).freeze

      def self.cast(raw)
        return raw unless raw.is_a?(Hash)

        values = CASTER.cast(raw)
        values.empty? ? nil : values
      end
    end
  end
end
