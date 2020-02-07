# Site configuration based on RailsSettings models,
# see <https://github.com/huacnlee/rails-settings-cached> for further info

class SiteConfig < RailsSettings::Base
  self.table_name = "site_configs"

  # the site configuration is cached, change this if you want to force update
  # the cache, or call SiteConfig.clear_cache
  cache_prefix { "v1" }

  # staff account
  field :staff_user_id, type: :integer, default: 1
  field :default_site_email, type: :string, default: "yo@dev.to"
  field :social_networks_handle, type: :string, default: "thepracticaldev"

  # images
  field :main_social_image, type: :string, default: "https://thepracticaldev.s3.amazonaws.com/i/6hqmcjaxbgbon8ydw93z.png"
  field :favicon_url, type: :string, default: "favicon.ico"
  field :logo_svg, type: :string, default: ""

  # rate limits
  field :rate_limit_follow_count_daily, type: :integer, default: 500
  field :rate_limit_comment_creation, type: :integer, default: 9
  field :rate_limit_published_article_creation, type: :integer, default: 9
  field :rate_limit_image_upload, type: :integer, default: 9
  field :rate_limit_email_recipient, type: :integer, default: 5

  # Google Analytics Reporting API v4
  # <https://developers.google.com/analytics/devguides/reporting/core/v4>
  field :ga_view_id, type: :string, default: ""
  field :ga_fetch_rate, type: :integer, default: 25

  # Mailchimp lists IDs
  # <https://mailchimp.com/developer/>
  field :mailchimp_newsletter_id, type: :string, default: ""
  field :mailchimp_sustaining_members_id, type: :string, default: ""
  field :mailchimp_tag_moderators_id, type: :string, default: ""
  field :mailchimp_community_moderators_id, type: :string, default: ""

  # Mailchimp webhook secret. Part of the callback URL in the Mailchimp settings.
  # <https://mailchimp.com/developer/guides/about-webhooks/#Webhooks_security>
  field :mailchimp_incoming_webhook_secret, type: :string, default: ""

  # Email digest frequency
  field :periodic_email_digest_max, type: :integer, default: 0
  field :periodic_email_digest_min, type: :integer, default: 2

  # Tags
  field :suggested_tags, type: :array, default: %w[beginners career computerscience javascript security ruby rails swift kotlin]
end
