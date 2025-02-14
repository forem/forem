module Settings
  # Basic UX settings that can be overridden by individual user preferences.
  class UserExperience < Base
    self.table_name = :settings_user_experiences

    HEX_COLOR_REGEX = /\A#(\h{6}|\h{3})\z/
    FEED_STRATEGIES = %w[basic large_forem_experimental].freeze
    FEED_STYLES = %w[basic rich compact].freeze
    COVER_IMAGE_FITS = %w[crop limit].freeze

    # The default font for all users that have not chosen a custom font yet
    setting :default_font, type: :string, default: "sans_serif"
    setting :feed_strategy, type: :string, default: "basic", validates: {
      inclusion: { in: FEED_STRATEGIES }
    }
    # basic (current default), rich (cover image on all posts), compact (more minimal)
    setting :feed_style, type: :string, default: "basic", validates: {
      inclusion: { in: FEED_STYLES }
    }
    setting :home_feed_minimum_score, type: :integer, default: 0
    setting :index_minimum_score, type: :integer, default: 0
    setting :index_minimum_date, type: :integer, default: 1_500_000_000
    setting :primary_brand_color_hex, type: :string, default: "#3b49df", validates: {
      format: {
        with: HEX_COLOR_REGEX,
        message: proc { I18n.t("models.settings.user_experience.message") }
      },
      color_contrast: true
    }
    setting :accent_background_color_hex, type: :string, default: nil, validates: {
      format: {
        with: HEX_COLOR_REGEX,
        message: proc { I18n.t("models.settings.user_experience.message") }
      },
      color_contrast: true
    }

    # cover images
    setting :cover_image_height, type: :integer, default: 420
    setting :cover_image_fit, type: :string, default: "crop", validates: {
      inclusion: { in: COVER_IMAGE_FITS }
    }

    # a non-public forem will redirect all unauthenticated pages to the registration page.
    # a public forem could have more fine-grained authentication (listings ar private etc.) in future
    setting :public, type: :boolean, default: true
    setting :tag_feed_minimum_score, type: :integer, default: 0
    setting :default_locale, type: :string, default: "en"
    setting :display_in_directory, type: :boolean, default: true
    setting :award_tag_minimum_score, type: :integer, default: 100

    # Mobile App
    setting :show_mobile_app_banner, type: :boolean, default: true

    # Head and footer content
    setting :head_content, type: :string, default: ""
    setting :bottom_of_body_content, type: :string, default: ""
  end
end
