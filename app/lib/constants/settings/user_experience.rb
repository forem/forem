module Constants
  module Settings
    module UserExperience
      def self.details
        {
          default_font: {
            description: I18n.t("lib.constants.settings.user_experience.determines_the_default_rea")
          },
          default_locale: {
            description: I18n.t("lib.constants.settings.user_experience.default_locale.description")
          },
          feed_strategy: {
            description: I18n.t("lib.constants.settings.user_experience.feed_strategy.description"),
            placeholder: I18n.t("lib.constants.settings.user_experience.feed_strategy.placeholder")
          },
          feed_style: {
            description: I18n.t("lib.constants.settings.user_experience.determines_which_default_f"),
            placeholder: I18n.t("lib.constants.settings.user_experience.basic_rich_or_compact")
          },
          home_feed_minimum_score: {
            description: I18n.t("lib.constants.settings.user_experience.minimum_score_needed_for_a"),
            placeholder: "0"
          },
          index_minimum_score: {
            description: I18n.t("lib.constants.settings.user_experience.index_minimum_score.description"),
            placeholder: "0"
          },
          primary_brand_color_hex: {
            description: I18n.t("lib.constants.settings.user_experience.determines_background_bord"),
            placeholder: "#0a0a0a"
          },
          tag_feed_minimum_score: {
            description: I18n.t("lib.constants.settings.user_experience.minimum_score_needed_for_a2"),
            placeholder: "0"
          }
        }
      end
    end
  end
end
