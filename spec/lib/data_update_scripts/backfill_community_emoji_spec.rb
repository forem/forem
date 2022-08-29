require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220815102733_backfill_community_emoji.rb",
)

describe DataUpdateScripts::BackfillCommunityEmoji do
  it "does not update the community_name if the community does not have a community_emoji" do
    allow(Settings::Community).to receive(:community_name).and_return("Emoji less Community")
    allow(Settings::Community).to receive(:community_emoji).and_return(nil)

    expect do
      described_class.new.run
    end.not_to change(Settings::Community, :community_name)
  end

  it "updates the community_name if the community has a community_emoji" do
    Settings::Community.community_name = "Emoji Community"
    Settings::Community.community_emoji = "🥐"

    described_class.new.run
    expect(Settings::Community.community_name).to eq("Emoji Community 🥐")
  end

  it "does not update the community_name if the community_emoji is already at the end" do
    Settings::Community.community_name = "Emoji Community 🥐"
    Settings::Community.community_emoji = "🥐"

    described_class.new.run
    expect(Settings::Community.community_name).to eq("Emoji Community 🥐")
  end
end
