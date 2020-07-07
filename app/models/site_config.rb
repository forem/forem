# Site configuration based on RailsSettings models,
# see <https://github.com/huacnlee/rails-settings-cached> for further info

# Defaults are currently very DEV-oriented.
# Should change to more truly generic values in future.

class SiteConfig < RailsSettings::Base
  self.table_name = "site_configs"

  # the site configuration is cached, change this if you want to force update
  # the cache, or call SiteConfig.clear_cache
  cache_prefix { "v1" }

  STACK_ICON = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 512 512' height='24' width='24'><path d='M398.044 29.719C359.712 10.555 309.267 0 256.001 0c-53.271 0-103.719 10.555-142.05 29.721-43.457 21.73-67.39 52.497-67.39 86.635v279.288c0 34.138 23.933 64.906 67.392 86.636C152.285 501.446 202.732 512 256.002 512c53.266 0 103.711-10.555 142.043-29.721 43.46-21.732 67.393-52.498 67.393-86.636V116.355c.001-34.138-23.934-64.904-67.394-86.636zM256.001 46.548c93.229 0 162.889 36.855 162.889 69.808 0 32.953-69.66 69.809-162.889 69.809-93.23 0-162.892-36.857-162.892-69.809 0-32.953 69.661-69.808 162.892-69.808zm162.89 349.095c0 32.953-69.662 69.809-162.891 69.809-93.23 0-162.892-36.856-162.892-69.809v-18.58c6.348 4.292 13.294 8.346 20.844 12.121 38.332 19.167 88.779 29.721 142.05 29.721 53.266 0 103.711-10.555 142.043-29.721 7.552-3.777 14.498-7.829 20.846-12.121v18.58zm.002-93.095h-.002c0 32.953-69.66 69.809-162.889 69.809-93.23 0-162.892-36.857-162.892-69.809v-18.58c6.348 4.292 13.294 8.343 20.844 12.119 38.332 19.168 88.779 29.722 142.05 29.722 53.266 0 103.711-10.555 142.043-29.722 7.552-3.777 14.498-7.829 20.846-12.123v18.584zm0-93.097h-.002c0 32.954-69.66 69.811-162.889 69.811-93.23 0-162.892-36.856-162.892-69.811v-18.579c6.348 4.292 13.294 8.343 20.844 12.118 38.331 19.167 88.779 29.721 142.05 29.721 53.266 0 103.711-10.555 142.043-29.721 7.552-3.777 14.498-7.829 20.846-12.121v18.582z'/></svg>"

  LIGHTNING_ICON = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 216.934 216.934' role='img' height='24' width='24'><title id='affvskzxb5z9lpzzd4192wivmlozbnqp'>Right sidebar</title><path d='M179.508 91.769a7.5 7.5 0 00-6.95-4.681h-32.323l26.743-77.131a7.5 7.5 0 00-12.373-7.777L39.089 116.98a7.499 7.499 0 005.288 12.82h32L47.26 206.781a7.499 7.499 0 0012.238 8.034L177.782 99.969a7.5 7.5 0 001.726-8.2zM73.196 180.61l21.051-55.657a7.5 7.5 0 00-7.015-10.153H62.563l79.623-79.13-19.575 56.462a7.5 7.5 0 007.085 9.957h24.37l-80.87 78.521z'></path></svg>"

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
  field :jobs_url, type: :string, default: "https://jobs.dev.to"
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

  field :navbar_left_icon_svg, type: :string, default: STACK_ICON
  field :navbar_right_icon_svg, type: :string, default: LIGHTNING_ICON

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
  field :rate_limit_user_subscription_creation, type: :integer, default: 3

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

  # User Experience
  # These are the default UX settings, which can be overridded by individual user preferences.
  field :feed_style, type: :string, default: "basic" # basic (current default), rich (cover image on all posts), compact (more minimal)

  # Broadcast
  field :welcome_notifications_live_at, type: :date
end
