module Color
  class CompareHex
    ACCENT_MODIFIERS = [1.14, 1.08, 1.06, 0.96, 0.9, 0.8, 0.7, 0.6].freeze
    BRIGHTNESS_FORMAT = "#%<r>02x%<g>02x%<b>02x".freeze
    OPACITY_FORMAT = "rgba(%<r>d, %<g>d, %<b>d, %<a>.2f)".freeze
    RGB_REGEX = /^#?(?<r>..)(?<g>..)(?<b>..)$/

    def initialize(hexes)
      @hexes = hexes.sort
    end

    def smallest
      hexes.first
    end

    def biggest
      hexes.last
    end

    def brightness(amount = 1)
      rgb = hex_to_rgb_hash(smallest).transform_values do |color|
        (color * amount).round
      end
      format(BRIGHTNESS_FORMAT, rgb)
    rescue StandardError
      smallest
    end

    # Returns the first valid hex string it finds (# + 6 digits)
    def accent(amount = 1)
      ACCENT_MODIFIERS.each do |modifier|
        with_brightness = brightness(modifier**amount)
        break with_brightness if with_brightness.size == 7
      end
    end

    def opacity(value = 0.0)
      rgba = hex_to_rgb_hash(smallest).merge(a: value)
      format(OPACITY_FORMAT, rgba)
    end

    private

    def hex_to_rgb_hash(hex)
      hex.match(RGB_REGEX).named_captures.map do |key, color|
        [key.to_sym, color.hex]
      end.to_h
    end

    attr_accessor :hexes
  end
end
