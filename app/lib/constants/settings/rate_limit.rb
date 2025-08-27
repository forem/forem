module Constants
  module Settings
    module RateLimit
      def self.details
        {
          spam_trigger_terms: {
            description: I18n.t("lib.constants.settings.rate_limit.spam.description"),
            placeholder: I18n.t("lib.constants.settings.rate_limit.spam.placeholder")
          },
          user_considered_new_days: {
            description: I18n.t("lib.constants.settings.rate_limit.new_days.description"),
            placeholder: ::Settings::RateLimit.user_considered_new_days
          },
          internal_content_description_spec: {
            description: I18n.t("lib.constants.settings.rate_limit.content_spec.description"),
            placeholder: I18n.t("lib.constants.settings.rate_limit.content_spec.placeholder")
          }
        }
      end
    end
  end
end
