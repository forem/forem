module DataUpdateScripts
  class NullifyEmptyTagColors
    def run
      # idempotent since the value restriction will answer no rows a second time
      Tag.where(bg_color_hex: "").update(bg_color_hex: nil)
      Tag.where(text_color_hex: "").update(text_color_hex: nil)
    end
  end
end
