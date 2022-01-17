require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220107215659_insert_google_ouauth2_connect_broadcast_message.rb",
)

describe DataUpdateScripts::InsertGoogleOuauth2ConnectBroadcastMessage do
  it "works without a Broadcast" do
    expect do
      described_class.new.run
    end.to change(Broadcast, :count).by(1)
  end

  it "works when a Broadcast already exists" do
    create(:google_oauth2_connect_broadcast)
    expect do
      described_class.new.run
    end.not_to change(Broadcast, :count)
  end
end
