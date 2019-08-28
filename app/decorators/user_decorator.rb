class UserDecorator < ApplicationDecorator
  delegate_all

  def cached_followed_tags
    Rails.cache.fetch("user-#{id}-#{updated_at}/followed_tags_11-30", expires_in: 20.hours) do
      follows_query = Follow.where(follower_id: id, followable_type: "ActsAsTaggableOn::Tag").pluck(:followable_id, :points)
      tags = Tag.where(id: follows_query.map { |f| f[0] }).order("hotness_score DESC")
      tags.each do |t|
        follow_query_item = follows_query.detect { |f| f[0] == t.id }
        t.points = follow_query_item[1]
      end
      tags
    end
  end

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

  def config_body_class
    body_class = ""
    body_class += config_theme.tr("_", "-")
    body_class = body_class + " " + config_font.tr("_", "-") + "-article-body" + " pro-status-#{pro?}"
    body_class
  end

  def assigned_color
    colors = [
      {
        bg: "#093656",
        text: "#ffffff"
      },
      {
        bg: "#19063A",
        text: "#dce9f3"
      },
      {
        bg: "#0D4D4B",
        text: "#fdf9f3"
      },
      {
        bg: "#61122f",
        text: "#ffffff"
      },
      {
        bg: "#2e0338",
        text: " #ffffff"
      },
      {
        bg: "#080E3B",
        text: "#ffffff"
      },
      {
        bg: "#010C1F",
        text: "#aebcd5"
      },
      {
        bg: "#d7dee2",
        text: "#022235"
      },
      {
        bg: "#161616",
        text: "#66e2d5"
      },
      {
        bg: "#1c0bba",
        text: "#c9d2dd"
      },
    ]
    colors[id % 10]
  end
end
