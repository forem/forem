module DataUpdateScripts
  class DisableListingFeature
    def run
      if URL.domain == "dev.to"
        FeatureFlag.enable(:listing_feature)
      else
        FeatureFlag.disable(:listing_feature)
      end
    end
  end
end
