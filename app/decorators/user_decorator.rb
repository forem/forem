class UserDecorator < ApplicationDecorator
  delegate_all

  def cached_followed_tags
    Rails.cache.fetch("user-#{id}-#{updated_at}/followed_tags", expires_in: 100.hours) do
      Tag.where(id: Follow.where(follower_id: id, followable_type: "ActsAsTaggableOn::Tag").pluck(:followable_id)).order("hotness_score DESC")
    end
  end

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
    colors = [
      {
        bg: "#093656",
        text: "#ffffff",
      },
      {
        bg: "#19063A",
        text: "#dce9f3",
      },
      {
        bg: "#0D4D4B",
        text: "#fdf9f3",
      },
      {
        bg: "#61122f",
        text: "#ffffff",
      },
      {
        bg: "#edebf6",
        text: " #070126",
      },
      {
        bg: "#080E3B",
        text: "#ffffff",
      },
      {
        bg: "#010C1F",
        text: "#aebcd5",
      },
      {
        bg: "#d7dee2",
        text: "#022235",
      },
      {
        bg: "#161616",
        text: "#66e2d5",
      },
      {
        bg: "#1c0bba",
        text: "#c9d2dd",
      },
    ]
    colors[id % 10]
  end
end
