require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20201229230456_remove_collective_noun_from_site_config.rb",
)

describe DataUpdateScripts::RemoveCollectiveNounFromSiteConfig do
  context "when collective_noun and collective_noun_disabled are removed from the Config" do
    it "does not alter the community_name" do
      allow(SiteConfig).to receive(:community_name).and_return("DEV Club")

      expect do
        described_class.new.run
      end.not_to change(SiteConfig, :community_name)

      expect(SiteConfig.community_name).to eq("DEV Club")
    end
  end
end
