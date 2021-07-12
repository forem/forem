module Constants
  module Settings
    module RateLimit
      DETAILS = {
        spam_trigger_terms: {
          description: "Individual (case insensitive) phrases that trigger spam alerts, comma separated.",
          placeholder: "used cars near you, pokemon go hack"
        },
        user_considered_new_days: {
          description: "The number of days a user is considered new. The default is 3 days, but you "\
                       "can disable this entirely by inputting 0.",
          placeholder: ::Settings::RateLimit.user_considered_new_days
        }
      }.freeze
    end
  end
end
