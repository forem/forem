# frozen_string_literal: true

module Faker
  class Color < Base
    class << self
      ##
      # Produces a hex color code.
      #
      # @return [String]
      #
      # @example
      #   Faker::Color.hex_color #=> "#31a785"
      #
      # @faker.version 1.5.0
      def hex_color
        format('#%06x', (rand * 0xffffff))
      end

      ##
      # Produces the name of a color.
      #
      # @return [String]
      #
      # @example
      #   Faker::Color.color_name #=> "yellow"
      #
      # @faker.version 1.6.2
      def color_name
        fetch('color.name')
      end

      # @private
      def single_rgb_color
        sample((0..255).to_a)
      end

      ##
      # Produces an array of integers representing an RGB color.
      #
      # @return [Array(Integer, Integer, Integer)]
      #
      # @example
      #   Faker::Color.rgb_color #=> [54, 233, 67]
      #
      # @faker.version 1.5.0
      def rgb_color
        Array.new(3) { single_rgb_color }
      end

      ##
      # Produces an array of floats representing an HSL color.
      # The array is in the form of `[hue, saturation, lightness]`.
      #
      # @return [Array(Float, Float, Float)]
      #
      # @example
      #   Faker::Color.hsl_color #=> [69.87, 0.66, 0.3]
      #
      # @faker.version 1.5.0
      def hsl_color
        [sample((0..360).to_a), rand.round(2), rand.round(2)]
      end

      ##
      # Produces an array of floats representing an HSLA color.
      # The array is in the form of `[hue, saturation, lightness, alpha]`.
      #
      # @return [Array(Float, Float, Float, Float)]
      #
      # @example
      #   Faker::Color.hsla_color #=> [154.77, 0.36, 0.9, 0.2]
      #
      # @faker.version 1.5.0
      def hsla_color
        hsl_color << rand.round(1)
      end
    end
  end
end
