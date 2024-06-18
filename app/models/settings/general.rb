module Settings
  class General < Base
    BANNER_USER_CONFIGS = %w[off logged_out_only all].freeze
    BANNER_PLATFORM_CONFIGS = %w[off all all_web desktop_web mobile_web mobile_app].freeze

    self.table_name = "site_configs"
    SOCIAL_MEDIA_SERVICES = %w[
      twitter facebook github instagram twitch mastodon
    ].freeze

    # Forem Team
    # [forem-fix] Remove channel name from Settings::General
    setting :article_published_slack_channel, type: :string, default: "activity"

    # Meta
    setting :admin_action_taken_at, type: :datetime, default: Time.current

    # Core setup
    setting :waiting_on_first_user, type: :boolean, default: !User.exists?
    setting :app_domain, type: :string, default: ApplicationConfig["APP_DOMAIN"]

    # API Tokens
    setting :health_check_token, type: :string
    setting :video_encoder_key, type: :string

    # Emails
    setting :contact_email, type: :string, default: ApplicationConfig["DEFAULT_EMAIL"]
    setting :periodic_email_digest, type: :integer, default: 2

    # Analytics and tracking
    setting :ga_tracking_id, type: :string, default: ApplicationConfig["GA_TRACKING_ID"]
    setting :ga_analytics_4_id, type: :string, default: ApplicationConfig["GA_ANALYTICS_4_ID"]
    setting :ga_api_secret, type: :string, default: ApplicationConfig["GA_API_SECRET"]
    setting :cookie_banner_user_context, type: :string, default: "off", validates: {
      inclusion: { in: BANNER_USER_CONFIGS }
    }
    setting :coolie_banner_platform_context, type: :string, default: "off", validates: {
      inclusion: { in: BANNER_PLATFORM_CONFIGS }
    }

    # Ahoy Tracking
    setting :ahoy_tracking, type: :boolean, default: false

    # Images
    setting :main_social_image,
            type: :string,
            default: proc { URL.local_image("social-media-cover.png") },
            validates: { url: true }

    setting :favicon_url, type: :string, default: proc { URL.local_image("favicon.ico") }
    setting :logo_png,
            type: :string,
            default: proc { URL.local_image("icon.png") },
            validates: { url: true }

    setting :original_logo, type: :string
    setting :resized_logo, type: :string
    setting :resized_logo_aspect_ratio, type: :string

    setting :enable_video_upload, type: :boolean, default: false

    # Mascot
    setting :mascot_user_id, type: :integer, default: nil
    setting :mascot_image_url,
            type: :string,
            default: proc { URL.local_image("mascot.png") },
            validates: { url: true }
    setting :mascot_image_description, type: :string, default: lambda {
                                                                 I18n.t("models.settings.general.the_community_mascot")
                                                               }
    setting :mascot_footer_image_url, type: :string, validates: { url: true }
    setting :mascot_footer_image_width, type: :integer, default: 52
    setting :mascot_footer_image_height, type: :integer, default: 120

    # Meta keywords
    setting :meta_keywords, type: :hash, default: {
      default: nil,
      article: nil,
      tag: nil
    }

    # Monetization
    setting :payment_pointer, type: :string
    setting :stripe_api_key, type: :string, default: ApplicationConfig["STRIPE_SECRET_KEY"]
    setting :stripe_publishable_key, type: :string, default: ApplicationConfig["STRIPE_PUBLISHABLE_KEY"]
    # Billboard-related. Not sure this is the best place for it, but it's a start.
    setting :billboard_enabled_countries, type: :hash, default: Geolocation::DEFAULT_ENABLED_COUNTRIES, validates: {
      enabled_countries_hash: true
    }

    # Newsletter
    # <https://mailchimp.com/developer/>
    setting :mailchimp_api_key, type: :string, default: ApplicationConfig["MAILCHIMP_API_KEY"]
    setting :mailchimp_newsletter_id, type: :string, default: ""
    setting :mailchimp_tag_moderators_id, type: :string, default: ""
    setting :mailchimp_community_moderators_id, type: :string, default: ""
    # Mailchimp webhook secret. Part of the callback URL in the Mailchimp settings.
    # <https://mailchimp.com/developer/guides/about-webhooks/#Webhooks_security>
    setting :mailchimp_incoming_webhook_secret, type: :string, default: ""

    # Onboarding
    setting :suggested_tags, type: :array, default: %w[]

    # Social Media
    setting :social_media_handles, type: :hash, default: {
      twitter: nil,
      facebook: nil,
      github: nil,
      instagram: nil,
      twitch: nil,
      mastodon: nil
    }
    setting :twitter_hashtag, type: :string

    # Tags
    setting :display_sidebar_active_discussions, type: :boolean, default: true
    setting :sidebar_tags, type: :array, default: %w[]

    # Broadcast
    setting :welcome_notifications_live_at, type: :date

    # Credits
    setting :credit_prices_in_cents, type: :hash, default: {
      small: 500,
      medium: 400,
      large: 300,
      xlarge: 250
    }

    # Push Notifications
    setting :push_notifications_ios_pem, type: :string

    # Feed
    setting :feed_pinned_article_id, type: :integer, validates: {
      existing_published_article_id: true, allow_nil: true
    }

    # Onboarding newsletter
    setting :onboarding_newsletter_content, type: :markdown
    setting :onboarding_newsletter_content_processed_html
    setting :onboarding_newsletter_opt_in_head
    setting :onboarding_newsletter_opt_in_subhead

    setting :geos_with_allowed_default_email_opt_in, type: :array, default: %w[]

    setting :default_content_language, type: :string, default: "en",
                                       validates: { inclusion: Languages::Detection.codes }

    # Algolia
    setting :algolia_application_id, type: :string, default: ApplicationConfig["ALGOLIA_APPLICATION_ID"]
    setting :algolia_api_key, type: :string, default: ApplicationConfig["ALGOLIA_API_KEY"]
    setting :algolia_search_only_api_key, type: :string, default: ApplicationConfig["ALGOLIA_SEARCH_ONLY_API_KEY"]
    setting :display_algolia_branding, type: :boolean, default: ApplicationConfig["ALGOLIA_DISPLAY_BRANDING"] == "true"

    def self.algolia_search_enabled?
      algolia_application_id.present? && algolia_search_only_api_key.present? && algolia_api_key.present?
    end

    def self.custom_newsletter_configured?
      onboarding_newsletter_content_processed_html.present? &&
        onboarding_newsletter_opt_in_head.present? &&
        onboarding_newsletter_opt_in_subhead.present?
    end

    def self.social_media_services
      SOCIAL_MEDIA_SERVICES.index_with do |name|
        social_media_handles[name]
      end
    end
  end
end
