module DataUpdateScripts
  class RemoveProfileAdminFlag
    def run
      FeatureFlag.remove(:profile_admin)
    end
  end
end
