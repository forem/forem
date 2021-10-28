module DataUpdateScripts
  class AddConnectFeatureFlag
    def run
      FeatureFlag.add(:connect)
    end
  end
end
