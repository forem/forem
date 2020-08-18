module Users
  class EstimateDefaultLanguage
    PREFERRED_LANGUAGES = ["en"].freeze

    def initialize(user)
      @user = user
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      estimated_default_language = estimate_default_language

      preferred_languages = PREFERRED_LANGUAGES
      preferred_languages |= [estimated_default_language] if estimated_default_language

      user.update_columns(
        language_settings: {
          estimated_default_language: estimated_default_language,
          preferred_languages: preferred_languages
        },
      )
    end

    private

    attr_reader :user

    def estimate_default_language
      identity = user.identities.find_by(provider: "twitter")
      user.email.to_s.end_with?(".jp") ? "ja" : language_from_twitter(identity)
    end

    # available twitter languages
    # https://developer.twitter.com/en/docs/developer-utilities/supported-languages/api-reference/get-help-languages
    def language_from_twitter(identity)
      return unless identity

      twitter_lang = identity.auth_data_dump["extra"]["raw_info"]["lang"]
      twitter_lang = "en" if twitter_lang == "en-gb"

      Languages.available?(twitter_lang) ? twitter_lang : nil
    end
  end
end
