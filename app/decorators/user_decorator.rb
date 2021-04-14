class UserDecorator < ApplicationDecorator
  WHITE_TEXT_COLORS = [
    {
      bg: "#093656",
      text: "#ffffff"
    },
    {
      bg: "#61122f",
      text: "#ffffff"
    },
    {
      bg: "#2e0338",
      text: "#ffffff"
    },
    {
      bg: "#080E3B",
      text: "#ffffff"
    },
  ].freeze

  def cached_followed_tags
    follows_map = Rails.cache.fetch("user-#{id}-#{following_tags_count}-#{last_followed_at&.rfc3339}/followed_tags",
                                    expires_in: 20.hours) do
      Follow.follower_tag(id).pluck(:followable_id, :points).to_h
    end

    tags = Tag.where(id: follows_map.keys).order(hotness_score: :desc)
    tags.each do |tag|
      tag.points = follows_map[tag.id]
    end
    tags
  end

  def darker_color(adjustment = 0.88)
    Color::CompareHex.new([enriched_colors[:bg], enriched_colors[:text]]).brightness(adjustment)
  end

  def enriched_colors
    if bg_color_hex.blank? || text_color_hex.blank?
      {
        bg: assigned_color[:bg],
        text: assigned_color[:text]
      }
    else
      {
        bg: bg_color_hex,
        text: text_color_hex
      }
    end
  end

  def config_font_name
    config_font.gsub("default", SiteConfig.default_font)
  end

  def config_body_class
    body_class = [
      config_theme.tr("_", "-"),
      "#{config_font_name.tr('_', '-')}-article-body",
      "trusted-status-#{trusted}",
      "#{config_navbar.tr('_', '-')}-header",
    ]
    body_class.join(" ")
  end

  def dark_theme?
    config_theme == "night_theme" || config_theme == "ten_x_hacker_theme"
  end

  def assigned_color
    colors = [
      {
        bg: "#19063A",
        text: "#dce9f3"
      },
      {
        bg: "#0D4D4B",
        text: "#fdf9f3"
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
    colors |= WHITE_TEXT_COLORS
    colors[(id || rand(100)) % 10]
  end

  # returns true if the user has been suspended and has no content
  def fully_banished?
    articles_count.zero? && comments_count.zero? && suspended?
  end

  def stackbit_integration?
    access_tokens.any?
  end

  def considered_new?
    min_days = Settings::RateLimit.user_considered_new_days
    return false unless min_days.positive?

    created_at.after?(min_days.days.ago)
  end
end
