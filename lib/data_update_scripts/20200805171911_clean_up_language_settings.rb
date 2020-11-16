module DataUpdateScripts
  class CleanUpLanguageSettings
    def run
      User.where("(language_settings->'preferred_languages') IS null").find_each do |user|
        language_settings = user.language_settings
        language_settings["preferred_languages"] = []

        language_settings["preferred_languages"] << "en" if language_settings["prefer_language_en"]
        language_settings["preferred_languages"] << "es" if language_settings["prefer_language_es"]
        language_settings["preferred_languages"] << "fr" if language_settings["prefer_language_fr"]
        language_settings["preferred_languages"] << "it" if language_settings["prefer_language_it"]
        language_settings["preferred_languages"] << "ja" if language_settings["prefer_language_ja"]
        language_settings["preferred_languages"] << "pt" if language_settings["prefer_language_pt"]

        user.update_column(:language_settings, language_settings)
      end
    end
  end
end
