module Constants
  module Settings
    module RateLimit
      def self.details
        {
          spam_trigger_terms: {
            description: I18n.t("lib.constants.settings.rate_limit.individual_case_insensitiv"),
            placeholder: I18n.t("lib.constants.settings.rate_limit.used_cars_near_you_pokemon")
          },
          user_considered_new_days: {
            description: I18n.t("lib.constants.settings.rate_limit.the_number_of_days_a_user"),
            placeholder: ::Settings::RateLimit.user_considered_new_days
          }
        }
      end
    end
  end
end
