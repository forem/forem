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

  DEFAULT_PROFILE_SUMMARY = -> { I18n.t("stories_controller.404_bio_not_found") }

  # The relevant attribute names for cached tags.  These are the attributes that we'll make
  # available in the front-end.  The list comes from the two places (see below for that list).
  #
  # @see app/controllers/async_info_controller.rb
  # @see app/services/articles/feeds/article_score_calculator_for_user.rb
  CACHED_TAGGED_BY_USER_ATTRIBUTES = %i[bg_color_hex hotness_score id name points text_color_hex].freeze

  # A proxy for a Tag object.  In app/services/articles/feeds/article_score_calculator_for_user.rb
  # we rely on method calls to the object.  (e.g. "tag.name").  This class helps us conform to that
  # expectation.
  #
  # @note A Struct in Rails can be cast "to_json" and uses its attributes.
  #
  # @see https://github.com/rails/rails/blob/main/activesupport/lib/active_support/core_ext/object/json.rb#L68-L72
  CachedTagByUser = Struct.new(*CACHED_TAGGED_BY_USER_ATTRIBUTES, keyword_init: true)

  # Return the relevant tags that the user follows and their points.
  #
  # @note We want to avoid caching ActiveRecord objects.
  #
  # @return [Array<UserDecorator::CachedTagByUser>]
  def cached_followed_tags
    cached_tag_attributes = Rails.cache.fetch(
      "user-#{id}-#{following_tags_count}-#{last_followed_at&.rfc3339}/user_followed_tags",
      expires_in: 20.hours,
    ) do
      Tag.followed_tags_for(follower: object).map { |tag| tag.slice(*CACHED_TAGGED_BY_USER_ATTRIBUTES) }
    end

    cached_tag_attributes.map do |cached_tag|
      CachedTagByUser.new(cached_tag)
    end
  end

  def darker_color(adjustment = 0.88)
    Color::CompareHex.new([enriched_colors[:bg], enriched_colors[:text]]).brightness(adjustment)
  end

  def enriched_colors
    if setting.brand_color1.blank?
      {
        bg: assigned_color[:bg],
        text: assigned_color[:text]
      }
    else
      {
        bg: setting.brand_color1,
        text: "#ffffff"
      }
    end
  end

  def config_body_class
    body_class = [
      setting.config_theme.tr("_", "-"),
      "#{setting.resolved_font_name.tr('_', '-')}-article-body",
      "trusted-status-#{trusted?}",
      "#{setting.config_navbar.tr('_', '-')}-header",
    ]
    body_class.join(" ")
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

  def considered_new?
    Settings::RateLimit.user_considered_new?(user: self)
  end

  # Returns the user's public email if it is set and the display_email_on_profile
  # settings is set to true.
  def profile_email
    return unless setting.display_email_on_profile?

    email
  end

  # Returns the users profile summary or a placeholder text
  def profile_summary
    profile.summary.presence || DEFAULT_PROFILE_SUMMARY.call
  end

  delegate :display_sponsors, to: :setting

  delegate :display_announcements, to: :setting
end
