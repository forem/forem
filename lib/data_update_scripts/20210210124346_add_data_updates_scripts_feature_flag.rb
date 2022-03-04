module DataUpdateScripts
  class AddDataUpdatesScriptsFeatureFlag
    def run
      FeatureFlag.add(:data_update_scripts)
    end
  end
end
