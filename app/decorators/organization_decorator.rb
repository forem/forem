class OrganizationDecorator < ApplicationDecorator
  delegate_all

  def darker_color(adjustment = 0.88)
    HexComparer.new([enriched_colors[:bg], enriched_colors[:text]]).brightness(adjustment)
  end

  def enriched_colors
    if bg_color_hex.blank?
      {
        bg: assigned_color[:bg],
        text: assigned_color[:text],
      }
    else
      {
        bg: bg_color_hex || assigned_color[:bg],
        text: text_color_hex || assigned_color[:text],
      }
    end
  end

  def assigned_color
    {
      bg: "#0a0a0a",
      text: "#ffffff",
    }
  end
end
