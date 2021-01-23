require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210123230648_insert_discord_connect_broadcast.rb",
)

describe DataUpdateScripts::InsertDiscordConnectBroadcast do
  it "Creates a new broadcast for discord connect" do
    described_class.new.run
    expect(Broadcast.find_by(title: "Welcome Notification: discord_connect")).not_to be_nil
  end

  it "Does not create a new broadcast for discord connect if exists" do
    create(:discord_connect_broadcast)
    described_class.new.run
    expect(Broadcast.where(title: "Welcome Notification: discord_connect").count).to be(1)
  end
end
