module DataUpdateScripts
  class AddMultipleReactionsFeatureFlag
    def run
      FeatureFlag.add :multiple_reactions
    end
  end
end
