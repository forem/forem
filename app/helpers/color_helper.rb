module ColorHelper
  def gradient_from_hex(hex = "#4F46E5")
    return { light: "#4f46e5", dark: "#312c8f" } unless hex.is_a? String

    @gradient_from_hex ||= {
      light: Color::CompareHex.new([hex]).brightness(1),
      dark: Color::CompareHex.new([hex]).brightness(0.625)
    }
  end
end
