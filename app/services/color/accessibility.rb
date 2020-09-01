module Color
  class Accessibility
    def initialize(hex)
      @hex = hex.delete("#")
    end

    def low_contrast?(compared_color = "ffffff", min_contrast = 4.5)
      WCAGColorContrast.ratio(@hex, compared_color.delete("#")) < min_contrast
    end
  end
end
