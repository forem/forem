module Users
  class Setting < ApplicationRecord
    self.table_name_prefix = "users_"

    enum editor_version: { v2: 0, v1: 1 }, _suffix: :editor
    enum config_font: { comic_sans: 1, monospace: 2, open_dyslexic: 3, sans_serif: 4, serif: 5 }
    enum inbox_type: { private: 0, open: 1 }, _suffix: :inbox
    enum config_navbar: { default: 0, static: 1 }
    enum config_theme: { default_theme: 0, minimal_light_theme: 1, night_theme: 2, pink_theme: 3,
                         ten_x_hacker_theme: 4 }

    MESSAGES = {
      invalid_config_font: "%<value>s is not a valid font selection"
    }.freeze

    before_validation :normalize_config_values

    validates :user_id, presence: true
    validates :config_font,
              inclusion: { in: config_fonts.merge({ default_font: 0 }).keys, message: MESSAGES[:invalid_config_font] }
    validates :config_font, presence: true

    validates :experience_level, numericality: { less_than_or_equal_to: 10 }, allow_blank: true
    validates :feed_referential_link, inclusion: { in: [true, false] }
    validates :feed_url, length: { maximum: 500 }, allow_nil: true

    validates :inbox_guidelines, length: { maximum: 250 }, allow_nil: true

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
      self.config_theme = config_theme&.tr(" ", "_")
      self.config_font = config_font&.tr(" ", "_")
      self.config_navbar = config_navbar&.tr(" ", "_")
    end
  end
end
