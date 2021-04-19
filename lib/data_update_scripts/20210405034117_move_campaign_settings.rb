module DataUpdateScripts
  class MoveCampaignSettings
    CAMPAIGN_SETTINGS = %w[
      articles_expiry_time
      articles_require_approval
      call_to_action
      featured_tags
      hero_html_variant_name
      sidebar_enabled
      sidebar_image
      url
    ].freeze

    def run
      return if Settings::Campaign.any?

      # All these fields got renamed so we migrate them explicitly
      CAMPAIGN_SETTINGS.each do |setting|
        Settings::Campaign.public_send(
          "#{setting}=",
          SiteConfig.public_send("campaign_#{setting}"),
        )
      end
    end
  end
end
