module Constants
  module Settings
    module Campaign
      def self.details
        {
          articles_expiry_time: {
            description: I18n.t("lib.constants.settings.campaign.articles_expiry.description"),
            placeholder: ""
          },
          articles_require_approval: {
            description: "",
            placeholder: I18n.t("lib.constants.settings.campaign.articles_approval.placeholder")
          },
          call_to_action: {
            description: I18n.t("lib.constants.settings.campaign.call_to_action.description"),
            placeholder: I18n.t("lib.constants.settings.campaign.call_to_action.placeholder")
          },
          display_name: {
            description: I18n.t("lib.constants.settings.campaign.display_name.description"),
            placeholder: I18n.t("lib.constants.settings.campaign.display_name.placeholder")
          },
          featured_tags: {
            description: I18n.t("lib.constants.settings.campaign.featured.description"),
            placeholder: I18n.t("lib.constants.settings.campaign.featured.placeholder")
          },
          hero_html_variant_name: {
            description: I18n.t("lib.constants.settings.campaign.hero_html.description"),
            placeholder: ""
          },
          sidebar_enabled: {
            description: "",
            placeholder: I18n.t("lib.constants.settings.campaign.sidebar_enabled.placeholder")
          },
          sidebar_image: {
            description: ::Constants::Settings::General::IMAGE_PLACEHOLDER,
            placeholder: I18n.t("lib.constants.settings.campaign.sidebar_image.placeholder")
          },
          url: {
            description: I18n.t("lib.constants.settings.campaign.url.description"),
            placeholder: I18n.t("lib.constants.settings.campaign.url.placeholder")
          }
        }
      end
    end
  end
end
