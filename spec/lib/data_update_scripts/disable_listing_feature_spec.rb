require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220204190754_disable_listing_feature.rb",
)

describe DataUpdateScripts::DisableListingFeature do
  before { allow(URL).to receive(:domain).and_return(domain) }

  context "when running on dev.to" do
    let(:domain) { "dev.to" }

    it "keeps the listing feature enabled" do
      described_class.new.run
      expect(Listing).to be_feature_enabled
    end
  end

  context "when running on some other site" do
    let(:domain) { "forem.dev" }

    it "keeps the listing feature enabled" do
      described_class.new.run
      expect(Listing).not_to be_feature_enabled
    end
  end
end
