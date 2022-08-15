module DataUpdateScripts
  class RemoveConnectFeatureFlag
    def run
      FeatureFlag.remove(:connect)
    end
  end
end
