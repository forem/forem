module DataUpdateScripts
  class PopulateSuggestedTagsFromSettings
    cattr_accessor :suggested_tags

    # We've added a new column on Tag (suggested) that needs to be populated
    # from a list that has previously been stored in Settings::General.suggested_tags
    # later this can go away
    def run(suggested_tags: settings_suggested_tags)
      return unless suggested_tags.any?

      Tag.where(name: suggested_tags).update_all suggested: true
    end

    private

    def settings_suggested_tags
      suggested_tags || Settings::General.suggested_tags
    end
  end
end
