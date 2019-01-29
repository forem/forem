class OrganizationDecorator < ApplicationDecorator
  delegate_all

  def darker_color(adjustment = 0.88)
    HexComparer.new([enriched_colors[:bg], enriched_colors[:text]]).brightness(adjustment)
  end

  def enriched_colors
    if bg_color_hex.blank?
      {
        bg: assigned_color[:bg],
        text: assigned_color[:text]
      }
    else
      {
        bg: bg_color_hex || assigned_color[:bg],
        text: text_color_hex || assigned_color[:text]
      }
    end
  end

  def assigned_color
    {
      bg: "#0a0a0a",
      text: "#ffffff"
    }
  end

  def key_profile_attributes
    "#{bg_color_hex}-#{text_color_hex}-#{path}-#{tag_line}-
    #{email}-#{company_size}-#{location}-#{summary}-#{cta_processed_html}-
    #{cta_button_url}-#{cta_button_text}-#{profile_image_url}-#{name}"
  end
end
