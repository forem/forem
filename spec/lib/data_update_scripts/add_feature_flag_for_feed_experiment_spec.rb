require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20211117204333_add_feature_flag_for_feed_experiment.rb",
)

describe DataUpdateScripts::AddFeatureFlagForFeedExperiment do
  after do
    FeatureFlag.remove(:ab_experiment_feed_strategy)
  end

  it "adds the :ab_experiment_feed_strategy flag" do
    expect do
      described_class.new.run
    end.to change { FeatureFlag.exist?(:ab_experiment_feed_strategy) }.from(false).to(true)
  end

  it "works if the flag is already available" do
    FeatureFlag.add(:ab_experiment_feed_strategy)

    expect do
      described_class.new.run
    end.not_to change { FeatureFlag.exist?(:ab_experiment_feed_strategy) }
  end
end
