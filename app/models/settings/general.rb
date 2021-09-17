module Settings
  class General < Base
    self.table_name = "site_configs"

    LIGHTNING_ICON = File.read(Rails.root.join("app/assets/images/lightning.svg")).freeze
    STACK_ICON = File.read(Rails.root.join("app/assets/images/stack.svg")).freeze

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

    # Email digest frequency
    setting :periodic_email_digest, type: :integer, default: 2

    # Google Analytics Tracking ID, e.g. UA-71991000-1
    setting :ga_tracking_id, type: :string, default: ApplicationConfig["GA_TRACKING_ID"]

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

    setting :logo_svg, type: :string

    setting :enable_video_upload, type: :boolean, default: false

    # Mascot
    setting :mascot_user_id, type: :integer, default: nil
    setting :mascot_image_url,
            type: :string,
            default: proc { URL.local_image("mascot.png") },
            validates: { url: true }
    setting :mascot_image_description, type: :string, default: "The community mascot"
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

    # Newsletter
    # <https://mailchimp.com/developer/>
    setting :mailchimp_api_key, type: :string, default: ApplicationConfig["MAILCHIMP_API_KEY"]
    setting :mailchimp_newsletter_id, type: :string, default: ""
    setting :mailchimp_sustaining_members_id, type: :string, default: ""
    setting :mailchimp_tag_moderators_id, type: :string, default: ""
    setting :mailchimp_community_moderators_id, type: :string, default: ""
    # Mailchimp webhook secret. Part of the callback URL in the Mailchimp settings.
    # <https://mailchimp.com/developer/guides/about-webhooks/#Webhooks_security>
    setting :mailchimp_incoming_webhook_secret, type: :string, default: ""

    # Onboarding
    setting :onboarding_background_image, type: :string, validates: { url: true }
    setting :suggested_tags, type: :array, default: %w[]
    setting :suggested_users, type: :array, default: %w[]
    setting :prefer_manual_suggested_users, type: :boolean, default: false

    # Social Media
    setting :social_media_handles, type: :hash, default: {
      twitter: nil,
      facebook: nil,
      github: nil,
      instagram: nil,
      twitch: nil
    }
    setting :twitter_hashtag, type: :string

    # Sponsors
    setting :sponsor_headline, default: "Community Sponsors"

    # Tags
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
  end
end
