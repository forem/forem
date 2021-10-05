require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210921235050_insert_forem_connect_broadcast_message.rb",
)

describe DataUpdateScripts::InsertForemConnectBroadcastMessage do
  it "works without a Broadcast" do
    expect do
      described_class.new.run
    end.to change(Broadcast, :count).by(1)
  end

  it "works when a Broadcast already exists" do
    create(:forem_connect_broadcast)
    expect do
      described_class.new.run
    end.not_to change(Broadcast, :count)
  end
end
