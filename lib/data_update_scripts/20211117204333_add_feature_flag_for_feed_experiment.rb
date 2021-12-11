module DataUpdateScripts
  class AddFeatureFlagForFeedExperiment
    def run
      FeatureFlag.add(:ab_experiment_feed_strategy)
    end
  end
end
