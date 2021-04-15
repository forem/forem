module Settings
  class CommunityContent < RailsSettings::Base
    self.table_name = :settings_community_contents

    # The configuration is cached, change this if you want to force update
    # the cache, or call Settings::CommunityContent.clear_cache
    cache_prefix { "v1" }

    # Define your fields
    # field :host, type: :string, default: "http://localhost:3000"
    # field :default_locale, default: "en", type: :string
  end
end
