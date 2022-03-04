require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210831052422_add_connect_feature_flag.rb",
)

describe DataUpdateScripts::AddConnectFeatureFlag do
  after do
    FeatureFlag.remove(:connect)
  end

  it "adds the :connect flag" do
    expect do
      described_class.new.run
    end.to change { FeatureFlag.exist?(:connect) }.from(false).to(true)
  end

  it "works if the flag is already available" do
    FeatureFlag.add(:connect)

    expect do
      described_class.new.run
    end.not_to change { FeatureFlag.exist?(:connect) }
  end
end
