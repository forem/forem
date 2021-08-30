module Settings
  # Basic UX settings that can be overriden by individual user preferences.
  class UserExperience < Base
    self.table_name = :settings_user_experiences

    HEX_COLOR_REGEX = /\A#(\h{6}|\h{3})\z/

    # The default font for all users that have not chosen a custom font yet
    setting :default_font, type: :string, default: "sans_serif"
    setting :feed_strategy, type: :string, default: "basic"
    # basic (current default), rich (cover image on all posts), compact (more minimal)
    setting :feed_style, type: :string, default: "basic"
    setting :home_feed_minimum_score, type: :integer, default: 0
    setting :primary_brand_color_hex, type: :string, default: "#3b49df", validates: {
      format: {
        with: HEX_COLOR_REGEX,
        message: "must be be a 3 or 6 character hex (starting with #)"
      },
      color_contrast: true
    }
    # a non-public forem will redirect all unauthenticated pages to the registration page.
    # a public forem could have more fine-grained authentication (listings ar private etc.) in future
    setting :public, type: :boolean, default: 0
    setting :tag_feed_minimum_score, type: :integer, default: 0
  end
end
