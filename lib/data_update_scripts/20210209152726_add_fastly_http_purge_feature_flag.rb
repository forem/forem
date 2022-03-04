module DataUpdateScripts
  class AddFastlyHttpPurgeFeatureFlag
    def run
      FeatureFlag.add(:fastly_http_purge)
    end
  end
end
