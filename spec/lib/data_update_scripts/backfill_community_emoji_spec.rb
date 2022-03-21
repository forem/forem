require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220201202226_backfill_community_emoji.rb",
)

describe DataUpdateScripts::BackfillCommunityEmoji do
  it "does not update the community_name if the community does not have a community_emoji" do
    Settings::Community.community_name = "Emoji-less Community"
    expect do
      described_class.new.run
    end.not_to change { Settings::Community.community_name }.from("Emoji-less Community")
  end

  it "updates the community_name if the community has a community_emoji" do
    Settings::Community.community_name = "Emoji Community"
    Settings::Community.community_emoji = "🥐"

    expect { described_class.new.run }
      .to change { Settings::Community.community_name }.from("Emoji Community").to("Emoji Community 🥐")
  end
end
