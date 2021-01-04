require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20201229230456_remove_collective_noun_from_site_config.rb",
)

describe DataUpdateScripts::RemoveCollectiveNounFromSiteConfig do
  context "when collective_noun and collective_noun_disabled are removed from the Config" do
    it "detroys the fields" do
      allow(SiteConfig).to receive(:collective_noun).and_return("Club")
      expect(SiteConfig.collective_noun).to eq("Club")
      described_class.new.run
      expect(SiteConfig).to include(:community_name)
      expect(SiteConfig).not_to include(var: %w[collective_noun collective_noun_disabled])
    end
  end
end
