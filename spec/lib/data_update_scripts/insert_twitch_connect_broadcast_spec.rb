require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210124045758_insert_twitch_connect_broadcast.rb",
)

describe DataUpdateScripts::InsertTwitchConnectBroadcast do
  it "Creates a new broadcast for Twitch connect" do
    described_class.new.run
    expect(Broadcast.find_by(title: "Welcome Notification: twitch_connect")).not_to be_nil
  end

  it "Does not create a new broadcast for twitch connect if exists" do
    create(:twitch_connect_broadcast)
    described_class.new.run
    expect(Broadcast.where(title: "Welcome Notification: twitch_connect").count).to be(1)
  end
end
