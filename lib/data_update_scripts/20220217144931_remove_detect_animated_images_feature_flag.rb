module DataUpdateScripts
  class RemoveDetectAnimatedImagesFeatureFlag
    def run
      FeatureFlag.remove(:detect_animated_images)
    end
  end
end
