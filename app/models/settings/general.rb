# Settings based on RailsSettings models,
# see <https://github.com/huacnlee/rails-settings-cached> for further info
module Settings
  class General < RailsSettings::Base
    self.table_name = "site_configs"

    # the configuration is cached, change this if you want to force update
    # the cache, or call Settings::General.clear_cache
    cache_prefix { "v1" }

    HEX_COLOR_REGEX = /\A#(\h{6}|\h{3})\z/.freeze
    LIGHTNING_ICON = File.read(Rails.root.join("app/assets/images/lightning.svg")).freeze
    STACK_ICON = File.read(Rails.root.join("app/assets/images/stack.svg")).freeze

    # Forem Team
    # [forem-fix] Remove channel name from Settings::General
    field :article_published_slack_channel, type: :string, default: "activity"

    # Meta
    field :admin_action_taken_at, type: :datetime, default: Time.current

    # Core setup
    field :waiting_on_first_user, type: :boolean, default: !User.exists?
    field :app_domain, type: :string, default: ApplicationConfig["APP_DOMAIN"]

    # API Tokens
    field :health_check_token, type: :string
    field :video_encoder_key, type: :string

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

    # To get default values
    def self.get_default(field)
      get_field(field)[:default]
    end
  end
end
