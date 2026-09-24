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

  it "busts the user-info cache when a role is removed" do
    user = create(:user, :community_leader_level_1)
    allow(user).to receive(:touch)

    described_class.call(user)

    expect(user).to have_received(:touch)
  end

  it "does not bust the cache when there is nothing to remove" do
    user = create(:user)
    allow(user).to receive(:touch)

    described_class.call(user)

    expect(user).not_to have_received(:touch)
  end

  it "resaves the user's articles so feed cards drop the leader icon" do
    user = create(:user, :community_leader_level_1)
    allow(Users::ResaveArticlesWorker).to receive(:perform_async)

    described_class.call(user)

    expect(Users::ResaveArticlesWorker).to have_received(:perform_async).with(user.id)
  end

  it "does not resave articles when there is nothing to remove" do
    allow(Users::ResaveArticlesWorker).to receive(:perform_async)

    described_class.call(create(:user))

    expect(Users::ResaveArticlesWorker).not_to have_received(:perform_async)
  end
end
