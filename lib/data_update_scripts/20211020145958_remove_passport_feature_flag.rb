module DataUpdateScripts
  class RemovePassportFeatureFlag
    def run
      FeatureFlag.remove(:forem_passport)
    end
  end
end
