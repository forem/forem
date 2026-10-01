require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20260930120000_backfill_agent_session_message_indices.rb",
)

describe DataUpdateScripts::BackfillAgentSessionMessageIndices do
  it "assigns positional indices to messages missing them" do
    session = AgentSession.create!(
      user: create(:user), title: "Agy", tool_name: "antigravity_cli",
      curated_data: { "messages" => [{ "role" => "user", "content" => [] }] }
    )
    session.update_column(:curated_data, { "messages" => [
                            { "role" => "user", "content" => [] },
                            { "role" => "assistant", "content" => [] },
                          ] })

    described_class.new.run

    expect(session.reload.messages.pluck("index")).to eq([0, 1])
  end
end
