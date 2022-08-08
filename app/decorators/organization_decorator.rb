class OrganizationDecorator < ApplicationDecorator
  def darker_color(adjustment = 0.88)
    Color::CompareHex.new([enriched_colors[:bg]]).brightness(adjustment)
  end

  def enriched_colors
    if bg_color_hex.blank?
      {
        bg: assigned_color[:bg]
      }
    else
      {
        bg: bg_color_hex
      }
    end
  end

  def assigned_color
    {
      bg: "#0a0a0a"
    }
  end

  def fully_banished?
    # We do not *currently* have the functionality to "ban" organizations.
    # We deal with them in other ways, but we still need to respond to this question.
    false
  end
end
