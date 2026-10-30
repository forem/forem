module Color
  class Accessibility
    class InvalidColorError < StandardError; end

    def initialize(hex)
      @hex = hex.delete("#")
    end

    def low_contrast?(compared_color = "ffffff", min_contrast = 4.5)
      contrast_ratio(compared_color) < min_contrast
    end

    def contrast_ratio(compared_color = "ffffff")
      ratio = ForemNative.wcag_contrast_ratio(@hex, compared_color.delete("#"))
      raise InvalidColorError, @hex if ratio.nil?

      ratio
    end
  end
end
