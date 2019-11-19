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

  # images
  field :main_social_image, type: :string, default: "https://thepracticaldev.s3.amazonaws.com/i/6hqmcjaxbgbon8ydw93z.png"
  field :favicon_url, type: :string, default: "favicon.ico"
  field :logo_svg, type: :string, default: ""

  # rate limits
  field :rate_limit_follow_count_daily, type: :integer, default: 500
end
