require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220111192031_insert_apple_connect_broadcast_message.rb",
)

describe DataUpdateScripts::InsertAppleConnectBroadcastMessage do
  it "works without a broadcast" do
    expect do
      described_class.new.run
    end.to change(Broadcast, :count).by(1)
  end

  it "works when a Broadcast already exists" do
    create(:apple_connect_broadcast)
    expect do
      described_class.new.run
    end.not_to change(Broadcast, :count)
  end
end
