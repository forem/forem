module Settings
  class Mascot < RailsSettings::Base
    self.table_name = :settings_mascots

    # The configuration is cached, change this if you want to force update
    # the cache, or call Settings::Mascot.clear_cache
    cache_prefix { "v1" }

    field :footer_image_height, type: :integer, default: 120
    field :footer_image_url, type: :string, validates: { url: true }
    field :footer_image_width, type: :integer, default: 52
    field :image_description, type: :string, default: "The community mascot"
    field :image_url,
          type: :string,
          default: proc { URL.local_image("mascot.png") },
          validates: { url: true }
    field :mascot_user_id, type: :integer, default: nil

    # NOTE: @citizen428 - This is duplicated for now, I will refactor once
    # all settings models have been extracted.
    def self.get_default(field)
      get_field(field)[:default]
    end
  end
end
