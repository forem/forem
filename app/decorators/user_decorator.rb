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

  DEFAULT_PROFILE_SUMMARY = "404 bio not found".freeze

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
    if setting.brand_color1.blank? || setting.brand_color2.blank?
      {
        bg: assigned_color[:bg],
        text: assigned_color[:text]
      }
    else
      {
        bg: setting.brand_color1,
        text: setting.brand_color2
      }
    end
  end

  def config_body_class
    body_class = [
      setting.config_theme.tr("_", "-"),
      "#{setting.resolved_font_name.tr('_', '-')}-article-body",
      "trusted-status-#{trusted}",
      "#{setting.config_navbar.tr('_', '-')}-header",
    ]
    body_class.join(" ")
  end

  def dark_theme?
    setting.config_theme == "night_theme" || setting.config_theme == "ten_x_hacker_theme"
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

  # Returns the user's public email if it is set and the display_email_on_profile
  # settings is set to true.
  def profile_email
    return unless setting.display_email_on_profile?

    email
  end

  # Returns the users profile summary or a placeholder text
  def profile_summary
    profile.summary.presence || DEFAULT_PROFILE_SUMMARY
  end

  delegate :display_sponsors, to: :setting

  delegate :display_announcements, to: :setting
end
