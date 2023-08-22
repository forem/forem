module DataUpdateScripts
  class RemoveMinimagickSocialFeatureFlag
    def run
      FeatureFlag.remove :minimagick_social_images
    end
  end
end
