# Site configuration based on RailsSettings models,
# see <https://github.com/huacnlee/rails-settings-cached> for further info

class SiteConfig < RailsSettings::Base
  self.table_name = "site_configs"

  # the site configuration is cached, change this if you want to force update
  # the cache, or call SiteConfig.clear_cache
  cache_prefix { "v1" }

  # images
  field :main_social_image, type: :string, default: "https://thepracticaldev.s3.amazonaws.com/i/6hqmcjaxbgbon8ydw93z.png"
  field :favicon_url, type: :string, default: "favicon.ico"

  # rate limits
  field :rate_limit_follow_count_daily, type: :integer, default: 500
end
