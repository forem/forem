module DataUpdateScripts
  class RemoveFastlyHttpPurgeFlag
    def run
      FeatureFlag.remove(:fastly_http_purge)
    end
  end
end
