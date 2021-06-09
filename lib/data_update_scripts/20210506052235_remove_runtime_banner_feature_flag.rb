module DataUpdateScripts
  class RemoveRuntimeBannerFeatureFlag
    def run
      FeatureFlag.remove(:runtime_banner)
    end
  end
end
