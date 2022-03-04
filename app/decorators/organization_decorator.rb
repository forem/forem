class OrganizationDecorator < ApplicationDecorator
  def darker_color(adjustment = 0.88)
    Color::CompareHex.new([enriched_colors[:bg], enriched_colors[:text]]).brightness(adjustment)
  end

  def enriched_colors
    if bg_color_hex.blank?
      {
        bg: assigned_color[:bg],
        text: assigned_color[:text]
      }
    else
      {
        bg: bg_color_hex,
        text: text_color_hex.presence || assigned_color[:text]
      }
    end
  end

  def assigned_color
    {
      bg: "#0a0a0a",
      text: "#ffffff"
    }
  end

  def fully_banished?
    # We do not *currently* have the functionality to "ban" organizations.
    # We deal with them in other ways, but we still need to respond to this question.
    false
  end
end
