require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20201228194641_append_collective_noun_to_community_name.rb",
)

describe DataUpdateScripts::AppendCollectiveNounToCommunityName do
  context "when collective_noun_disabled is false" do
    it "appends the collective_noun to the community_name" do
      allow(SiteConfig).to receive(:collective_noun).and_return("Club")
      described_class.new.run
      expect(SiteConfig.collective_noun_disabled).to eq(false)
      expect(SiteConfig.community_name).to eq("DEV(local) Club")
    end
  end

  context "when collective_noun_disabled is true" do
    it "does not append the collective_noun to the community_name" do
      allow(SiteConfig).to receive(:collective_noun_disabled).and_return(true)
      described_class.new.run
      expect(SiteConfig.community_name).to eq("DEV(local)")
    end
  end
end
