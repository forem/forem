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

  def sponsorship_color_hex
    hexes = { "gold" => "linear-gradient(to right, #faf0e6 8%, #faf3e6 18%, #fcf6eb 33%);",
              "silver" => "linear-gradient(to right, #e3e3e3 8%, #f0eded 18%, #e8e8e8 33%);",
              "bronze" => "linear-gradient(to right, #ebe2d3 8%, #f5eee1 18%, #ede6d8 33%);" }
    hexes[sponsorship_level]
  end
end
