require "color"

module Color
  class Accessibility
    def initialize(hex)
      @hex = hex.delete("#")
    end

    def low_contrast?(compared_color = "ffffff", min_contrast = 4.5)
      WCAGColorContrast.ratio(@hex, compared_color.delete("#")) < min_contrast
    end

    def reduce_brightness(compared_color = "ffffff", min_contrast = 4.5)
      n = 0
      hex_color = @hex
      while WCAGColorContrast.ratio(hex_color, compared_color) < min_contrast
        n -= 1
        hex_color = Color::RGB.from_html(hex_color).adjust_brightness(n).hex
      end
      hex_color
    end
  end
end
