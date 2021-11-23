module DataUpdateScripts
  class AddFeatureFlagFeaturedStoryMustHaveAdminPage
    def run
      FeatureFlag.add(:featured_story_must_have_main_image)
    end
  end
end
