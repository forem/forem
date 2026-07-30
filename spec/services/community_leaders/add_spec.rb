require "rails_helper"

RSpec.describe CommunityLeaders::Add, type: :service do
  let(:user) { create(:user) }

  it "grants the level 1 role" do
    result = described_class.call(user, :community_leader_level_1)

    expect(user.community_leader_level_1?).to be true
    expect(user.community_leader?).to be true
    expect(result.success?).to be true
  end

  it "grants the level 2 role" do
    result = described_class.call(user, :community_leader_level_2)

    expect(user.community_leader_level_2?).to be true
    expect(user.community_leader?).to be true
    expect(result.success?).to be true
  end

  it "swaps roles so user is assigned one community leader role at a time" do
    described_class.call(user, :community_leader_level_1)
    described_class.call(user, :community_leader_level_2)

    expect(user.community_leader_level_2?).to be true
    expect(user.community_leader_level_1?).to be false
  end

  it "grants the trusted role" do
    allow(TagModerators::AddTrustedRole).to receive(:call)

    described_class.call(user, :community_leader_level_1)

    expect(user.has_trusted_role?).to be true
  end

  it "returns a failure for an invalid role and grants no role" do
    result = described_class.call(user, :not_a_leader_role)

    expect(result.success?).to be false
    expect(result.errors).to include("Invalid community leader role")
    expect(user.community_leader?).to be false
  end
end
