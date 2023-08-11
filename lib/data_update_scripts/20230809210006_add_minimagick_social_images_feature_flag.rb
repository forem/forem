module DataUpdateScripts
  class AddMinimagickSocialImagesFeatureFlag
    def run
      FeatureFlag.add :minimagick_social_images
    end
  end
end
