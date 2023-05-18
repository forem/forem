require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20230518035338_add_hero_billboard_feature_flag.rb",
)

describe DataUpdateScripts::AddHeroBillboardFeatureFlag do
  after do
    FeatureFlag.remove(:hero_billboard)
  end

  it "adds the :hero_billboard flag" do
    expect do
      described_class.new.run
    end.to change { FeatureFlag.exist?(:hero_billboard) }.from(false).to(true)
  end

  it "works if the flag is already available" do
    FeatureFlag.add(:hero_billboard)

    expect do
      described_class.new.run
    end.not_to change { FeatureFlag.exist?(:hero_billboard) }
  end
end
