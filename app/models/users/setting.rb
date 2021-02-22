module Users
   class Setting < ApplicationRecord
    self.table_name_prefix = "users_"

    EDITORS = %w[v1 v2].freeze
    FONTS = %w[serif sans_serif monospace comic_sans open_dyslexic].freeze
    INBOXES = %w[open private].freeze
    NAVBARS = %w[default static].freeze
    THEMES = %w[default night_theme pink_theme minimal_light_theme ten_x_hacker_theme].freeze

    MESSAGES = {
      invalid_config_font: "%<value>s is not a valid font selection",
      invalid_config_navbar: "%<value>s is not a valid navbar value",
      invalid_config_theme: "%<value>s is not a valid theme",
      invalid_editor_version: "%<value>s must be either v1 or v2",
    }.freeze

    before_validation :set_config_input

    validates :config_font, inclusion: { in: FONTS + ["default".freeze], message: MESSAGES[:invalid_config_font] }
    validates :config_font, presence: true
    validates :config_navbar, inclusion: { in: NAVBARS, message: MESSAGES[:invalid_config_navbar] }
    validates :config_navbar, presence: true
    validates :config_theme, inclusion: { in: THEMES, message: MESSAGES[:invalid_config_theme] }
    validates :config_theme, presence: true
    validates :editor_version, inclusion: { in: EDITORS, message: MESSAGES[:invalid_editor_version] }

    validates :experience_level, numericality: { less_than_or_equal_to: 10 }, allow_blank: true
    validates :feed_referential_link, inclusion: { in: [true, false] }
    validates :feed_url, length: { maximum: 500 }, allow_nil: true

    validates :inbox_guidelines, length: { maximum: 250 }, allow_nil: true
    validates :inbox_type, inclusion: { in: INBOXES }

    validate :validate_feed_url, if: :feed_url_changed?

    private

    def validate_feed_url
      return if feed_url.blank?

      valid = Feeds::ValidateUrl.call(feed_url)

      errors.add(:feed_url, "is not a valid RSS/Atom feed") unless valid
    rescue StandardError => e
      errors.add(:feed_url, e.message)
    end

    def set_config_input
      self.config_theme = config_theme&.tr(" ", "_")
      self.config_font = config_font&.tr(" ", "_")
      self.config_navbar = config_navbar&.tr(" ", "_")
    end

   end
 end
