module ColorHelper
  def gradient_from(_hex = "#000000")
    brand_color = Settings::UserExperience.primary_brand_color_hex
    {
      light: Color::CompareHex.new([brand_color]).brightness(0.9),
      dark: Color::CompareHex.new([brand_color]).brightness(0.6)
    }
  end
end
