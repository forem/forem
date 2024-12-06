# frozen_string_literal: true

module Ferrum
  class RGBA
    def initialize(red, green, blue, alpha)
      self.red = red
      self.green = green
      self.blue = blue
      self.alpha = alpha

      validate
    end

    def to_h
      { r: red, g: green, b: blue, a: alpha }
    end

    private

    attr_accessor :red, :green, :blue, :alpha

    def validate
      [red, green, blue].each(&method(:validate_color))
      validate_alpha
    end

    def validate_color(value)
      return if value.is_a?(Integer) && Range.new(0, 255).include?(value)

      raise ArgumentError, "Wrong value of #{value} should be Integer from 0 to 255"
    end

    def validate_alpha
      return if alpha.is_a?(Float) && Range.new(0.0, 1.0).include?(alpha)

      raise ArgumentError,
            "Wrong alpha value #{alpha} should be Float between 0.0 (fully transparent) and 1.0 (fully opaque)"
    end
  end
end
