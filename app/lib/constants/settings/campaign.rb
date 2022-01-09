module Constants
  module Settings
    module Campaign
      def self.details
        {
          articles_expiry_time: {
            description: I18n.t("lib.constants.settings.campaign.sets_the_expiry_time_for_a"),
            placeholder: ""
          },
          articles_require_approval: {
            description: "",
            placeholder: I18n.t("lib.constants.settings.campaign.campaign_stories_show_up_o")
          },
          call_to_action: {
            description: I18n.t("lib.constants.settings.campaign.this_text_populates_the_ca"),
            placeholder: I18n.t("lib.constants.settings.campaign.share_your_project")
          },
          featured_tags: {
            description: I18n.t("lib.constants.settings.campaign.posts_with_which_tags_will"),
            placeholder: I18n.t("lib.constants.settings.campaign.list_of_campaign_tags_comm")
          },
          hero_html_variant_name: {
            description: I18n.t("lib.constants.settings.campaign.hero_htmlvariant_name"),
            placeholder: ""
          },
          sidebar_enabled: {
            description: "",
            placeholder: I18n.t("lib.constants.settings.campaign.campaign_sidebar_enabled_o")
          },
          sidebar_image: {
            description: ::Constants::Settings::General::IMAGE_PLACEHOLDER,
            placeholder: I18n.t("lib.constants.settings.campaign.used_at_the_top_of_the_cam")
          },
          url: {
            description: I18n.t("lib.constants.settings.campaign.https_url_com_lander"),
            placeholder: I18n.t("lib.constants.settings.campaign.url_campaign_sidebar_image")
          }
        }
      end
    end
  end
end
