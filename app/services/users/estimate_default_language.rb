module Users
  class EstimateDefaultLanguage
    def initialize(user)
      @user = user
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      preferred_languages = ["en"]
      preferred_languages |= [estimated_default_language] if estimated_default_language
      user.update_columns(language_settings: { estimated_default_language: estimated_default_language,
                                               preferred_languages: preferred_languages })
    end

    private

    attr_reader :user

    def estimated_default_language
      return @estimated_default_language if defined? @estimated_default_language

      identity = user.identities.find_by(provider: "twitter")
      @estimated_default_language = user.email.to_s.end_with?(".jp") ? "ja" : language_from_twitter(identity)
    end

    # available twitter languages
    # https://developer.twitter.com/en/docs/developer-utilities/supported-languages/api-reference/get-help-languages
    def language_from_twitter(identity)
      return nil unless identity

      twitter_lang = identity.auth_data_dump["extra"]["raw_info"]["lang"]
      return "en" if twitter_lang == "en-gb"

      Languages.available?(twitter_lang) ? twitter_lang : nil
    end
  end
end
