module DataUpdateScripts
  class AddBillboardLocationTargetingFeatureFlag
    def run
      FeatureFlag.add Geolocation::FEATURE_FLAG
    end
  end
end
