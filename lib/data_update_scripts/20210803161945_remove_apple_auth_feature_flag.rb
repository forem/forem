module DataUpdateScripts
  class RemoveAppleAuthFeatureFlag
    def run
      FeatureFlag.remove(:apple_auth)
    end
  end
end
