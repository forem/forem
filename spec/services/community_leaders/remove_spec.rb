require "rails_helper"

RSpec.describe CommunityLeaders::Remove, type: :service do
  it "revokes a level 1 leader role" do
    user = create(:user, :community_leader_level_1)
    described_class.call(user)
    expect(user.community_leader?).to be false
  end

  it "revokes a level 2 leader role" do
    user = create(:user, :community_leader_level_2)
    described_class.call(user)
    expect(user.community_leader?).to be false
  end

  it "leaves the trusted role in place" do
    user = create(:user, :community_leader_level_1, :trusted)
    described_class.call(user)
    expect(user.has_trusted_role?).to be true
  end

  it "is a no-op for a non-leader and returns success" do
    user = create(:user)
    result = described_class.call(user)
    expect(result.success?).to be true
    expect(user.community_leader?).to be false
  end
end
