require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20201228194641_append_collective_noun_to_community_name.rb",
)

describe DataUpdateScripts::AppendCollectiveNounToCommunityName do
  context "when collective_noun_disabled is false" do
    it "appends the collective_noun to the community_name" do
      described_class.new.run
      expect(SiteConfig.collective_noun_disabled).to eq(false)
      expect(SiteConfig.community_name).to eq("DEV(local) Community")
    end
  end

  context "when collective_noun_disabled is true" do
    it "does not append the collective_noun to the community_name" do
      SiteConfig.collective_noun_disabled = true
      described_class.new.run
      expect(SiteConfig.collective_noun_disabled).to eq(true)
      expect(SiteConfig.community_name).to eq("DEV(local)")
    end
  end
end
