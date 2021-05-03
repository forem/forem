# Site configuration based on RailsSettings models,
# see <https://github.com/huacnlee/rails-settings-cached> for further info

class SiteConfig < RailsSettings::Base
  self.table_name = "site_configs"

  # the site configuration is cached, change this if you want to force update
  # the cache, or call SiteConfig.clear_cache
  cache_prefix { "v1" }

  HEX_COLOR_REGEX = /\A#(\h{6}|\h{3})\z/.freeze
  LIGHTNING_ICON = File.read(Rails.root.join("app/assets/images/lightning.svg")).freeze
  STACK_ICON = File.read(Rails.root.join("app/assets/images/stack.svg")).freeze

  # Forem Team
  # [forem-fix] Remove channel name from SiteConfig
  field :article_published_slack_channel, type: :string, default: "activity"

  # Meta
  field :admin_action_taken_at, type: :datetime, default: Time.current

  # Core setup
  field :waiting_on_first_user, type: :boolean, default: !User.exists?
  field :app_domain, type: :string, default: ApplicationConfig["APP_DOMAIN"]

  # API Tokens
  field :health_check_token, type: :string
  field :video_encoder_key, type: :string

  # NOTE: @citizen428 These two values will be removed once we fully migrated
  # to Settings::Authentication. Until then we need them for the data update script.
  field :allowed_registration_email_domains, type: :array, default: %w[], validates: {
    valid_domain_csv: true
  }
  field :authentication_providers, type: :array, default: %w[]

  # NOTE: @citizen428 The whole block of campaign settings will be removed once
  # we fully migrated to Settings::Campaign across the fleet.
  # Campaign
  field :campaign_call_to_action, type: :string, default: "Share your project"
  field :campaign_hero_html_variant_name, type: :string, default: ""
  field :campaign_featured_tags, type: :array, default: %w[]
  field :campaign_sidebar_enabled, type: :boolean, default: 0
  field :campaign_sidebar_image, type: :string, default: nil, validates: {
    url: true
  }
  field :campaign_url, type: :string, default: nil
  field :campaign_articles_require_approval, type: :boolean, default: 0
  field :campaign_articles_expiry_time, type: :integer, default: 4
  # Community Content
  # NOTE: @citizen428 All these settings will be removed once we full migrated
  # to Settings::Community across the fleet.
  field :community_name, type: :string, default: ApplicationConfig["COMMUNITY_NAME"] || "New Forem"
  field :community_emoji, type: :string, default: "🌱", validates: { emoji_only: true }
  # collective_noun and collective_noun_disabled have been added back temporarily for
  # a data_update script, but will be removed in a future PR!
  field :collective_noun, type: :string, default: "Community"
  field :collective_noun_disabled, type: :boolean, default: false
  field :community_description, type: :string
  field :community_member_label, type: :string, default: "user"
  field :tagline, type: :string
  field :community_copyright_start_year,
        type: :integer,
        default: ApplicationConfig["COMMUNITY_COPYRIGHT_START_YEAR"] || Time.zone.today.year
  field :staff_user_id, type: :integer, default: 1
  field :experience_low, type: :string, default: "Total Newbies"
  field :experience_high, type: :string, default: "Experienced Users"

  # Emails
  field :email_addresses, type: :hash, default: {
    default: ApplicationConfig["DEFAULT_EMAIL"],
    contact: ApplicationConfig["DEFAULT_EMAIL"],
    business: ApplicationConfig["DEFAULT_EMAIL"],
    privacy: ApplicationConfig["DEFAULT_EMAIL"],
    members: ApplicationConfig["DEFAULT_EMAIL"]
  }

  # Email digest frequency
  field :periodic_email_digest, type: :integer, default: 2

  # Google Analytics Tracking ID, e.g. UA-71991000-1
  field :ga_tracking_id, type: :string, default: ApplicationConfig["GA_TRACKING_ID"]

  # Images
  field :main_social_image,
        type: :string,
        default: proc { URL.local_image("social-media-cover.png") },
        validates: { url: true }

  field :favicon_url, type: :string, default: proc { URL.local_image("favicon.ico") }
  field :logo_png,
        type: :string,
        default: proc { URL.local_image("icon.png") },
        validates: { url: true }

  field :logo_svg, type: :string

  field :enable_video_upload, type: :boolean, default: false

  # Mascot
  field :mascot_user_id, type: :integer, default: nil
  field :mascot_image_url,
        type: :string,
        default: proc { URL.local_image("mascot.png") },
        validates: { url: true }
  field :mascot_image_description, type: :string, default: "The community mascot"
  field :mascot_footer_image_url, type: :string, validates: { url: true }
  field :mascot_footer_image_width, type: :integer, default: 52
  field :mascot_footer_image_height, type: :integer, default: 120

  # Meta keywords
  field :meta_keywords, type: :hash, default: {
    default: nil,
    article: nil,
    tag: nil
  }

  # Monetization
  field :payment_pointer, type: :string
  field :stripe_api_key, type: :string, default: ApplicationConfig["STRIPE_SECRET_KEY"]
  field :stripe_publishable_key, type: :string, default: ApplicationConfig["STRIPE_PUBLISHABLE_KEY"]
  field :shop_url, type: :string

  # Newsletter
  # <https://mailchimp.com/developer/>
  field :mailchimp_api_key, type: :string, default: ApplicationConfig["MAILCHIMP_API_KEY"]
  field :mailchimp_newsletter_id, type: :string, default: ""
  field :mailchimp_sustaining_members_id, type: :string, default: ""
  field :mailchimp_tag_moderators_id, type: :string, default: ""
  field :mailchimp_community_moderators_id, type: :string, default: ""
  # Mailchimp webhook secret. Part of the callback URL in the Mailchimp settings.
  # <https://mailchimp.com/developer/guides/about-webhooks/#Webhooks_security>
  field :mailchimp_incoming_webhook_secret, type: :string, default: ""

  # Onboarding
  field :onboarding_background_image, type: :string, validates: { url: true }
  field :suggested_tags, type: :array, default: %w[]
  field :suggested_users, type: :array, default: %w[]
  field :prefer_manual_suggested_users, type: :boolean, default: false

  # Rate limits and spam prevention
  # NOTE: @citizen428 These will be removed once we migrated to the new settings
  # model across the fleet.
  field :rate_limit_follow_count_daily, type: :integer, default: 500
  field :rate_limit_comment_creation, type: :integer, default: 9
  field :rate_limit_comment_antispam_creation, type: :integer, default: 1
  field :rate_limit_listing_creation, type: :integer, default: 1
  field :rate_limit_published_article_creation, type: :integer, default: 9
  field :rate_limit_published_article_antispam_creation, type: :integer, default: 1
  field :rate_limit_organization_creation, type: :integer, default: 1
  field :rate_limit_reaction_creation, type: :integer, default: 10
  field :rate_limit_image_upload, type: :integer, default: 9
  field :rate_limit_email_recipient, type: :integer, default: 5
  field :rate_limit_article_update, type: :integer, default: 30
  field :rate_limit_send_email_confirmation, type: :integer, default: 2
  field :rate_limit_feedback_message_creation, type: :integer, default: 5
  field :rate_limit_user_update, type: :integer, default: 15
  field :rate_limit_user_subscription_creation, type: :integer, default: 3

  field :spam_trigger_terms, type: :array, default: []

  field :user_considered_new_days, type: :integer, default: 3

  # Social Media
  field :social_media_handles, type: :hash, default: {
    twitter: nil,
    facebook: nil,
    github: nil,
    instagram: nil,
    twitch: nil
  }
  field :twitter_hashtag, type: :string

  # Sponsors
  field :sponsor_headline, default: "Community Sponsors"

  # Tags
  field :sidebar_tags, type: :array, default: %w[]

  # NOTE: @citizen428 - These will be removed once we migrated to Settings::UserExperience
  # across the whole fleet.
  # User Experience
  # These are the default UX settings, which can be overridded by individual user preferences.
  # basic (current default), rich (cover image on all posts), compact (more minimal)
  field :feed_style, type: :string, default: "basic"
  # a non-public forem will redirect all unauthenticated pages to the registration page.
  # a public forem could have more fine-grained authentication (listings ar private etc.) in future
  field :public, type: :boolean, default: 0
  # The default font for all users that have not chosen a custom font yet
  field :default_font, type: :string, default: "sans_serif"
  field :primary_brand_color_hex, type: :string, default: "#3b49df", validates: {
    format: {
      with: HEX_COLOR_REGEX,
      message: "must be be a 3 or 6 character hex (starting with #)"
    },
    color_contrast: true
  }
  field :feed_strategy, type: :string, default: "basic"
  field :tag_feed_minimum_score, type: :integer, default: 0
  field :home_feed_minimum_score, type: :integer, default: 0

  # Broadcast
  field :welcome_notifications_live_at, type: :date

  # Credits
  field :credit_prices_in_cents, type: :hash, default: {
    small: 500,
    medium: 400,
    large: 300,
    xlarge: 250
  }

  # Push Notifications
  field :push_notifications_ios_pem, type: :string

  # Returns true if we are operating on a local installation, false otherwise
  def self.local?
    app_domain.include?("localhost")
  end

  # Used where we need to keep old DEV features around but don't want to/cannot
  # expose them to other communities.
  def self.dev_to?
    app_domain == "dev.to"
  end

  # To get default values
  def self.get_default(field)
    get_field(field)[:default]
  end
end
