module Settings
  class Campaign < RailsSettings::Base
    self.table_name = :settings_campaigns

    # The configuration is cached, change this if you want to force update
    # the cache, or call Settings::Campaign.clear_cache
    cache_prefix { "v1" }

    # Define your fields
    field :articles_expiry_time, type: :integer, default: 4
    field :articles_require_approval, type: :boolean, default: 0
    field :call_to_action, type: :string, default: "Share your project"
    field :featured_tags, type: :array, default: %w[]
    field :hero_html_variant_name, type: :string, default: ""
    field :sidebar_enabled, type: :boolean, default: 0
    field :sidebar_image, type: :string, default: nil, validates: { url: true }
    field :url, type: :string, default: nil
  end
end
