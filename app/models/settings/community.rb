module Settings
  class Community < RailsSettings::Base
    self.table_name = :settings_communities

    # The configuration is cached, change this if you want to force update
    # the cache, or call Settings::Community.clear_cache
    cache_prefix { "v1" }

    field :copyright_start_year,
          type: :integer,
          default: ApplicationConfig["COMMUNITY_COPYRIGHT_START_YEAR"] || Time.zone.today.year
    field :community_description, type: :string
    field :community_emoji, type: :string, default: "🌱", validates: { emoji_only: true }
    field :community_name, type: :string, default: ApplicationConfig["COMMUNITY_NAME"] || "New Forem"
    field :member_label, type: :string, default: "user"
    field :staff_user_id, type: :integer, default: 1
    field :tagline, type: :string
  end
end
