# Site configuration based on RailsSettings models,
# see <https://github.com/huacnlee/rails-settings-cached> for further info

class SiteConfig < RailsSettings::Base
  self.table_name = "site_configs"

  # the site configuration is cached, change this if you want to force update
  # the cache, or call SiteConfig.clear_cache
  cache_prefix { "v1" }

  STACK_ICON = File.read(Rails.root.join("app/assets/images/stack.svg")).freeze
  LIGHTNING_ICON = File.read(Rails.root.join("app/assets/images/lightning.svg")).freeze

  field :waiting_on_first_user, type: :boolean, default: !User.exists?

  # API Tokens
  field :health_check_token, type: :string

  # Authentication
  field :allow_email_password_registration, type: :boolean, default: false
  field :authentication_providers, type: :array, default: Authentication::Providers.available
  field :twitter_key, type: :string, default: ApplicationConfig["TWITTER_KEY"]
  field :twitter_secret, type: :string, default: ApplicationConfig["TWITTER_SECRET"]
  field :github_key, type: :string, default: ApplicationConfig["GITHUB_KEY"]
  field :github_secret, type: :string, default: ApplicationConfig["GITHUB_SECRET"]
  field :facebook_key, type: :string
  field :facebook_secret, type: :string

  # Campaign
  field :campaign_hero_html_variant_name, type: :string, default: ""
  field :campaign_featured_tags, type: :array, default: %w[]
  field :campaign_sidebar_enabled, type: :boolean, default: 0
  field :campaign_sidebar_image, type: :string, default: nil
  field :campaign_url, type: :string, default: nil
  field :campaign_articles_require_approval, type: :boolean, default: 0

  # Community Content
  field :community_name, type: :string, default: ApplicationConfig["COMMUNITY_NAME"] || "New Forem"
  field :community_description, type: :string
  field :community_member_label, type: :string, default: "user"
  field :community_action, type: :string
  field :tagline, type: :string
  field :community_copyright_start_year, type: :integer,
                                         default: ApplicationConfig["COMMUNITY_COPYRIGHT_START_YEAR"] ||
                                           Time.zone.today.year
  field :staff_user_id, type: :integer, default: 1

  # Emails
  field :email_addresses, type: :hash, default: {
    default: ApplicationConfig["DEFAULT_EMAIL"],
    business: ApplicationConfig["DEFAULT_EMAIL"],
    privacy: ApplicationConfig["DEFAULT_EMAIL"],
    members: ApplicationConfig["DEFAULT_EMAIL"]
  }

  # Email digest frequency
  field :periodic_email_digest_max, type: :integer, default: 0
  field :periodic_email_digest_min, type: :integer, default: 2

  # Jobs
  field :jobs_url, type: :string
  field :display_jobs_banner, type: :boolean, default: false

  # Google Analytics Reporting API v4
  # <https://developers.google.com/analytics/devguides/reporting/core/v4>
  field :ga_view_id, type: :string, default: ""

  # Images
  field :main_social_image, type: :string
  field :favicon_url, type: :string, default: "favicon.ico"
  field :logo_png, type: :string
  field :logo_svg, type: :string
  field :secondary_logo_url, type: :string

  field :left_navbar_svg_icon, type: :string, default: STACK_ICON
  field :right_navbar_svg_icon, type: :string, default: LIGHTNING_ICON

  # Mascot
  field :mascot_user_id, type: :integer, default: 1
  field :mascot_image_url, type: :string
  field :mascot_image_description, type: :string, default: "The community mascot"
  field :mascot_footer_image_url, type: :string
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
  field :mailchimp_newsletter_id, type: :string, default: ""
  field :mailchimp_sustaining_members_id, type: :string, default: ""
  field :mailchimp_tag_moderators_id, type: :string, default: ""
  field :mailchimp_community_moderators_id, type: :string, default: ""
  # Mailchimp webhook secret. Part of the callback URL in the Mailchimp settings.
  # <https://mailchimp.com/developer/guides/about-webhooks/#Webhooks_security>
  field :mailchimp_incoming_webhook_secret, type: :string, default: ""

  # Onboarding
  field :onboarding_logo_image, type: :string
  field :onboarding_background_image, type: :string
  field :onboarding_taskcard_image, type: :string
  field :suggested_tags, type: :array, default: %w[]
  field :suggested_users, type: :array, default: %w[]

  # Rate limits
  field :rate_limit_follow_count_daily, type: :integer, default: 500
  field :rate_limit_comment_creation, type: :integer, default: 9
  field :rate_limit_listing_creation, type: :integer, default: 1
  field :rate_limit_published_article_creation, type: :integer, default: 9
  field :rate_limit_organization_creation, type: :integer, default: 1
  field :rate_limit_reaction_creation, type: :integer, default: 10
  field :rate_limit_image_upload, type: :integer, default: 9
  field :rate_limit_email_recipient, type: :integer, default: 5
  field :rate_limit_article_update, type: :integer, default: 30
  field :rate_limit_send_email_confirmation, type: :integer, default: 2
  field :rate_limit_feedback_message_creation, type: :integer, default: 5
  field :rate_limit_user_update, type: :integer, default: 5
  field :rate_limit_user_subscription_creation, type: :integer, default: 3

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

  # User Experience
  # These are the default UX settings, which can be overridded by individual user preferences.
  # basic (current default), rich (cover image on all posts), compact (more minimal)
  field :feed_style, type: :string, default: "basic"
  # a non-public forem will redirect all unauthenticated pages to the registration page.
  # a public forem could have more fine-grained authentication (listings ar private etc.) in future
  field :public, type: :boolean, default: 0
  # The default font for all users that have not chosen a custom font yet
  field :default_font, type: :string, default: "sans_serif"
  field :primary_brand_color_hex, type: :string, default: "#3b49df"

  # Broadcast
  field :welcome_notifications_live_at, type: :date

  # Credits
  field :credit_prices_in_cents, type: :hash, default: {
    small: 500,
    medium: 400,
    large: 300,
    xlarge: 250
  }
end
