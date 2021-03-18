module Users
  class Setting < ApplicationRecord
    self.table_name_prefix = "users_"

    enum editor_versions: { v2: 0, v1: 1 }, _suffix: :editor
    enum config_fonts: { comic_sans: 1, monospace: 2, open_dyslexic: 3, sans_serif: 4, serif: 5 }
    enum inbox_types: { private: 0, open: 1 }, _suffix: :inbox
    enum config_navbars: { default: 0, static: 1 }
    enum config_themes: { default_theme: 0, minimal_light_theme: 1, night_theme: 2, pink_theme: 3,
                          ten_x_hacker_theme: 4 }

    MESSAGES = {
      invalid_config_font: "%<value>s is not a valid font selection",
      invalid_config_navbar: "%<value>s is not a valid navbar value",
      invalid_config_theme: "%<value>s is not a valid theme",
      invalid_editor_version: "%<value>s must be either v1 or v2"
    }.freeze

    before_validation :normalize_config_values

    validates :user_id, presence: true
    validates :config_font,
              inclusion: { in: config_fonts.merge({ default_font: 0 }).keys, message: MESSAGES[:invalid_config_font] }
    validates :config_font, presence: true
    validates :config_navbar, inclusion: { in: config_navbars.keys, message: MESSAGES[:invalid_config_navbar] }
    validates :config_navbar, presence: true
    validates :config_theme, inclusion: { in: config_themes.keys, message: MESSAGES[:invalid_config_theme] }
    validates :config_theme, presence: true
    validates :editor_version, inclusion: { in: editor_versions.keys, message: MESSAGES[:invalid_editor_version] }

    validates :experience_level, numericality: { less_than_or_equal_to: 10 }, allow_blank: true
    validates :feed_referential_link, inclusion: { in: [true, false] }
    validates :feed_url, length: { maximum: 500 }, allow_nil: true

    validates :inbox_guidelines, length: { maximum: 250 }, allow_nil: true
    validates :inbox_type, inclusion: { in: inbox_types.keys }

    validate :validate_feed_url, if: :feed_url_changed?

    private

    def validate_feed_url
      return if feed_url.blank?

      valid = Feeds::ValidateUrl.call(feed_url)

      errors.add(:feed_url, "is not a valid RSS/Atom feed") unless valid
    rescue StandardError => e
      errors.add(:feed_url, e.message)
    end

    def normalize_config_values
      self.config_theme = config_theme
      self.config_font = config_font
      self.config_navbar = config_navbar
    end
  end
end
