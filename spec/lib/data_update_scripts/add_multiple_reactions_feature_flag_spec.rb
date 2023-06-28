require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20221220131148_add_multiple_reactions_feature_flag.rb",
)

describe DataUpdateScripts::AddMultipleReactionsFeatureFlag do
  before do
    allow(FeatureFlag).to receive(:add)
  end

  it "adds the feature flag" do
    described_class.new.run
    expect(FeatureFlag).to have_received(:add).with(:multiple_reactions)
  end
end
