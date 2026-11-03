module Color
  class Accessibility
    class InvalidColorError < StandardError; end

    def initialize(hex)
      @hex = hex.delete("#")
    end

    def low_contrast?(compared_color = "ffffff", min_contrast = 4.5)
      ratio = ForemNative.wcag_contrast_ratio(@hex, compared_color.delete("#"))
      raise InvalidColorError, @hex if ratio.nil?

      ratio < min_contrast
    end
  end
end
