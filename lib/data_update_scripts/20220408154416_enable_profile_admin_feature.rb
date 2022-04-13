module DataUpdateScripts
  class EnableProfileAdminFeature
    def run
      FeatureFlag.enable(:profile_admin)
    end
  end
end
