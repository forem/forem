module Users
  class Setting < ApplicationRecord
    self.table_name_prefix = "users_"

    HEX_COLOR_REGEXP = /\A#?(?:\h{6}|\h{3})\z/.freeze

    belongs_to :user, touch: true
    scope :with_feed, -> { where.not(feed_url: [nil, ""]) }

    enum editor_version: { v2: 0, v1: 1 }, _suffix: :editor
    enum config_font: { default: 0, comic_sans: 1, monospace: 2, open_dyslexic: 3, sans_serif: 4, serif: 5 },
         _suffix: :font
    enum inbox_type: { private: 0, open: 1 }, _suffix: :inbox
    enum config_navbar: { default: 0, static: 1 }, _suffix: :navbar
    enum config_theme: { default: 0, minimal_light_theme: 1, night_theme: 2, pink_theme: 3,
                         ten_x_hacker_theme: 4 }

    validates :brand_color1,
              :brand_color2,
              format: { with: HEX_COLOR_REGEXP, message: "is not a valid hex color" },
              allow_nil: true
    validates :user_id, presence: true
    validates :experience_level, numericality: { less_than_or_equal_to: 10 }, allow_blank: true
    validates :feed_referential_link, inclusion: { in: [true, false] }
    validates :feed_url, length: { maximum: 500 }, allow_nil: true
    validates :inbox_guidelines, length: { maximum: 250 }, allow_nil: true

    validate :validate_feed_url, if: :feed_url_changed?

    def resolved_font_name
      config_font.gsub("default", Settings::UserExperience.default_font)
    end

    private

    def validate_feed_url
      return if feed_url.blank?

      valid = Feeds::ValidateUrl.call(feed_url)

      errors.add(:feed_url, "is not a valid RSS/Atom feed") unless valid
    rescue StandardError => e
      errors.add(:feed_url, e.message)
    end
  end
end
