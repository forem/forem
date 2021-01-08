module DataUpdateScripts
  class RemoveFeedsImportFeatureFlag
    def run
      FeatureFlag.remove(:feeds_import)
    end
  end
end
