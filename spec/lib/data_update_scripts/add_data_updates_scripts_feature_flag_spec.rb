require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210210124346_add_data_updates_scripts_feature_flag.rb",
)

describe DataUpdateScripts::AddDataUpdatesScriptsFeatureFlag do
  after do
    FeatureFlag.remove(:data_update_scripts)
  end

  it "adds the :data_update_scripts flag", :aggregate_failures do
    expect do
      described_class.new.run
    end.to change { FeatureFlag.exist?(:data_update_scripts) }.from(false).to(true)
  end

  it "works if the flag is already available" do
    FeatureFlag.add(:data_update_scripts)

    expect do
      described_class.new.run
    end.not_to change { FeatureFlag.exist?(:data_update_scripts) }
  end
end
