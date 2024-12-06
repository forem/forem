require "wcag_color_contrast/version"

module WCAGColorContrast
  class InvalidColorError < StandardError; end

  # Helper method for WCAGColorContrast::Ratio.new#ratio.
  def self.ratio(*args)
    Ratio.new.ratio(*args)
  end

  def self.relative_luminance(rgb)
    Ratio.new.relative_luminance(rgb)
  end

  class Ratio
    # Calculate contast ratio beetween RGB1 and RGB2.
    def ratio(rgb1, rgb2)
      raise InvalidColorError, rgb1 unless valid_rgb?(rgb1)
      raise InvalidColorError, rgb2 unless valid_rgb?(rgb2)

      srgb1 = rgb_to_srgba(rgb1)
      srgb2 = rgb_to_srgba(rgb2)

      l1 = srgb_lightness(srgb1)
      l2 = srgb_lightness(srgb2)

      l1 > l2 ? (l1 + 0.05) / (l2 + 0.05) : (l2 + 0.05) / (l1 + 0.05)
    end

    # Calculate the relative luminance for an rgb color
    def relative_luminance(rgb)
      raise InvalidColorError, rgb unless valid_rgb?(rgb)

      srgb = rgb_to_srgba(rgb)
      srgb_lightness(srgb)
    end

    private

    # Convert RGB color to sRGB.
    def rgb_to_srgba(rgb)
      rgb << rgb if rgb.size == 3
      [
        rgb.slice(0,2).to_i(16) / 255.0,
        rgb.slice(2,2).to_i(16) / 255.0,
        rgb.slice(4,2).to_i(16) / 255.0
      ]
    end

    # Calculate lightness for sRGB color.
    def srgb_lightness(srgb)
      r, g, b = srgb
      0.2126 * (r <= 0.03928 ? r / 12.92 : ((r + 0.055) / 1.055) ** 2.4) +
      0.7152 * (g <= 0.03928 ? g / 12.92 : ((g + 0.055) / 1.055) ** 2.4) +
      0.0722 * (b <= 0.03928 ? b / 12.92 : ((b + 0.055) / 1.055) ** 2.4)
    end

    # Validate RGB string.
    def valid_rgb?(rgb)
      rgb && (rgb.match(/^[a-f0-9]{3}$/i) || rgb.match(/^[a-f0-9]{6}$/i))
    end
  end
end
