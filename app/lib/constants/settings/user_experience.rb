module Constants
  module Settings
    module UserExperience
      def self.details
        {
          default_font: {
            description: I18n.t("lib.constants.settings.user_experience.default_font.description")
          },
          default_locale: {
            description: I18n.t("lib.constants.settings.user_experience.default_locale.description")
          },
          feed_strategy: {
            description: I18n.t("lib.constants.settings.user_experience.feed_strategy.description"),
            placeholder: I18n.t("lib.constants.settings.user_experience.feed_strategy.placeholder")
          },
          feed_style: {
            description: I18n.t("lib.constants.settings.user_experience.feed_style.description"),
            placeholder: I18n.t("lib.constants.settings.user_experience.feed_style.placeholder")
          },
          cover_image_height: {
            description: I18n.t("lib.constants.settings.user_experience.cover_image_height.description"),
            placeholder: I18n.t("lib.constants.settings.user_experience.cover_image_height.placeholder")
          },
          cover_image_fit: {
            description: I18n.t("lib.constants.settings.user_experience.cover_image_fit.description"),
            placeholder: I18n.t("lib.constants.settings.user_experience.cover_image_fit.placeholder")
          },
          home_feed_minimum_score: {
            description: I18n.t("lib.constants.settings.user_experience.home_feed.description"),
            placeholder: "0"
          },
          index_minimum_score: {
            description: I18n.t("lib.constants.settings.user_experience.index_minimum_score.description"),
            placeholder: "0"
          },
          index_minimum_date: {
            description: I18n.t("lib.constants.settings.user_experience.index_minimum_date.description"),
            placeholder: "1500000000"
          },
          primary_brand_color_hex: {
            description: I18n.t("lib.constants.settings.user_experience.primary_hex.description"),
            placeholder: "#0a0a0a"
          },
          tag_feed_minimum_score: {
            description: I18n.t("lib.constants.settings.user_experience.tag_feed.description"),
            placeholder: "0"
          },
          head_content: {
            description: I18n.t("lib.constants.settings.user_experience.head_content.description"),
            placeholder: I18n.t("lib.constants.settings.user_experience.head_content.placeholder")
          },
          bottom_of_body_content: {
            description: I18n.t("lib.constants.settings.user_experience.bottom_of_body_content.description"),
            placeholder: I18n.t("lib.constants.settings.user_experience.bottom_of_body_content.placeholder")
          }
        }
      end
    end
  end
end
