# Site configuration based on RailsSettings models,
# see <https://github.com/huacnlee/rails-settings-cached> for further info

# Defaults are currently very DEV-oriented.
# Should change to more truly generic values in future.

class SiteConfig < RailsSettings::Base
  self.table_name = "site_configs"

  # the site configuration is cached, change this if you want to force update
  # the cache, or call SiteConfig.clear_cache
  cache_prefix { "v1" }

  # API Tokens
  field :health_check_token, type: :string

  # Authentication
  field :authentication_providers, type: :array, default: Authentication::Providers.available

  # Campaign
  field :campaign_hero_html_variant_name, type: :string, default: ""
  field :campaign_featured_tags, type: :array, default: %w[]
  field :campaign_sidebar_enabled, type: :boolean, default: 0
  field :campaign_sidebar_image, type: :string, default: nil
  field :campaign_url, type: :string, default: nil
  field :campaign_articles_require_approval, type: :boolean, default: 0

  # Community Content
  field :community_description, type: :string, default: "A constructive and inclusive social network. Open source and radically transparent."
  field :community_member_description, type: :string, default: "amazing humans who code."
  field :community_member_label, type: :string, default: "user"
  field :community_action, type: :string, default: "coding"
  field :tagline, type: :string, default: "We're a place where coders share, stay up-to-date and grow their careers."

  # Emails
  field :email_addresses, type: :hash, default: {
    default: ApplicationConfig["DEFAULT_EMAIL"],
    business: "partners@dev.to",
    privacy: "privacy@dev.to",
    members: "members@dev.to"
  }

  # Email digest frequency
  field :periodic_email_digest_max, type: :integer, default: 0
  field :periodic_email_digest_min, type: :integer, default: 2

  # Jobs
  field :jobs_url, type: :string, default: "https://jobs.dev.to/"
  field :display_jobs_banner, type: :boolean, default: false

  # Google Analytics Reporting API v4
  # <https://developers.google.com/analytics/devguides/reporting/core/v4>
  field :ga_view_id, type: :string, default: ""
  field :ga_fetch_rate, type: :integer, default: 25

  # Images
  field :main_social_image, type: :string, default: "https://thepracticaldev.s3.amazonaws.com/i/6hqmcjaxbgbon8ydw93z.png"
  field :favicon_url, type: :string, default: "favicon.ico"
  field :logo_png, type: :string, default: "https://practicaldev-herokuapp-com.freetls.fastly.net/assets/devlogo-pwa-512.png"
  field :logo_svg, type: :string, default: ""
  field :primary_sticker_image_url, type: :string, default: "https://practicaldev-herokuapp-com.freetls.fastly.net/assets/rainbowdev.svg"

  # Mascot
  field :mascot_user_id, type: :integer, default: 1
  field :mascot_image_url, type: :string, default: "https://dev-to-uploads.s3.amazonaws.com/i/y5767q6brm62skiyywvc.png"
  field :mascot_footer_image_url, type: :string, default: "https://dev-to-uploads.s3.amazonaws.com/i/wmv3mtusjwb3r13d5h2f.png"
  field :mascot_image_description, type: :string, default: "Sloan, the sloth mascot"

  # Meta keywords
  field :meta_keywords, type: :hash, default: {
    default: nil,
    article: nil,
    tag: nil
  }

  # Monetization
  field :payment_pointer, type: :string, default: "$ilp.uphold.com/24HhrUGG7ekn" # Experimental
  field :shop_url, type: :string, default: "https://shop.dev.to"

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
  field :onboarding_logo_image, type: :string, default: "https://dev.to/assets/purple-dev-logo.png"
  field :onboarding_background_image, type: :string, default: "https://dev.to/assets/onboarding-background-white.png"
  field :onboarding_taskcard_image, type: :string, default: "https://practicaldev-herokuapp-com.freetls.fastly.net/assets/staggered-dev.svg"
  field :suggested_tags, type: :array, default: %w[beginners career computerscience javascript security ruby rails swift kotlin]
  field :suggested_users, type: :array, default: %w[ben jess peter maestromac andy liana]

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

  # Social Media
  field :staff_user_id, type: :integer, default: 1
  field :social_media_handles, type: :hash, default: {
    twitter: nil,
    facebook: nil,
    github: nil,
    instagram: nil,
    twitch: nil
  }
  field :twitter_hashtag, type: :string, default: "#DEVCommunity"

  # Tags
  field :sidebar_tags, type: :array, default: %w[help challenge discuss explainlikeimfive meta watercooler]

  # Broadcast
  field :welcome_notifications_live_at, type: :date
end
