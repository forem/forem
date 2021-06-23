module Settings
  # We use this model to back the "Get Started" form of the config admin page.
  class Mandatory
    include ActiveModel::Naming

    MAPPINGS = {
      community_name: Settings::Community,
      community_description: Settings::Community,

      suggested_tags: SiteConfig,
      suggested_users: SiteConfig
    }.freeze

    MAPPINGS.each do |setting, settings_model|
      delegate setting, "#{setting}=", to: settings_model
    end

    def self.keys
      MAPPINGS.keys
    end

    def self.missing
      MAPPINGS.reject do |settings, settings_model|
        settings_model.public_send(settings).present?
      end.keys
    end
  end
end
