module Color
  # Readable values derived from an organization's brand color.  The brand color can be anything,
  # so text on it and text in it can't be assumed to read in either theme.
  class BrandPalette
    MIN_CONTRAST = 4.5
    LIGHT_THEME_CARD = "#ffffff".freeze
    DARK_THEME_CARD = "#141311".freeze # --card-bg in themes/dark.css
    WHITE = "#ffffff".freeze
    BLACK = "#000000".freeze
    MIX_STEPS = (0..10).map { |step| step / 10.0 }.freeze

    def initialize(hex)
      @hex = hex.delete("#").then { |digits| digits.size == 3 ? digits.gsub(/./) { |d| d * 2 } : digits }
    end

    # White stays unless it's unreadable on the brand color and black reads better.
    def text_on_brand(background = "##{hex}")
      accessibility = Accessibility.new(background)
      return WHITE unless accessibility.low_contrast?(WHITE, MIN_CONTRAST)

      accessibility.contrast_ratio(BLACK) > accessibility.contrast_ratio(WHITE) ? BLACK : WHITE
    end

    # The brand color as text or an icon on a card, in each theme.
    def accent_text_light
      readable_on(LIGHT_THEME_CARD, BLACK)
    end

    def accent_text_dark
      readable_on(DARK_THEME_CARD, WHITE)
    end

    # CompareHex#brightness doesn't cap channels at 255, so scaling up can produce an invalid color.
    def lighter(amount, only_values: false)
      values = channels.map { |channel| [(channel * amount).round, 255].min }
      only_values ? values.join(", ") : to_hex(values)
    end

    private

    attr_reader :hex

    def readable_on(card, target)
      MIX_STEPS.each do |step|
        mixed = mix(target, step)
        return mixed unless Accessibility.new(mixed).low_contrast?(card, MIN_CONTRAST)
      end
      target
    end

    def mix(target, step)
      target_channels = target.delete("#").scan(/../).map(&:hex)
      to_hex(channels.zip(target_channels).map { |from, to| (from + ((to - from) * step)).round })
    end

    def channels
      hex.scan(/../).map(&:hex)
    end

    def to_hex(values)
      format(CompareHex::BRIGHTNESS_FORMAT, r: values[0], g: values[1], b: values[2])
    end
  end
end
