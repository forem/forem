module Users
  class EstimateDefaultLanguage
    def initialize(user)
      @user = user
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      identity = user.identities.find_by(provider: "twitter")
      if user.email.end_with?(".jp")
        user.update(estimated_default_language: "ja", prefer_language_ja: true)
      elsif identity
        lang = identity.auth_data_dump["extra"]["raw_info"]["lang"]
        user.update(:estimated_default_language => lang,
                    "prefer_language_#{lang}" => true)
      end
    end

    private

    attr_reader :user
  end
end
