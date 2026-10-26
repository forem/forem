require "rails_helper"

RSpec.describe Users::BustProfileIdentityCacheWorker, type: :worker do
  let(:user) { create(:user) }

  before do
    allow(EdgeCache::PurgeByKey).to receive(:call)
    allow(EdgeCache::Bust).to receive(:call)
  end

  it "busts the profile identity cache key" do
    described_class.new.perform(user.id)
    expect(EdgeCache::PurgeByKey).to have_received(:call).with(
      user.profile_identity_record_key,
      fallback_paths: user.profile_cache_bust_paths,
    )
    expect(EdgeCache::Bust).not_to have_received(:call)
  end

  it "explicitly busts current and previous username paths when old_username is present" do
    user.update_columns(old_username: "thebitforge_dev", old_old_username: "thebitforge_old")

    described_class.new.perform(user.id)

    expect(EdgeCache::PurgeByKey).to have_received(:call).with(
      user.profile_identity_record_key,
      fallback_paths: [
        user.path,
        "/profile_preview_cards/#{user.id}",
        "/api/users/#{user.id}",
        "/thebitforge_dev",
        "/thebitforge_old",
      ],
    )
    expect(EdgeCache::Bust).to have_received(:call).with([user.path, "/thebitforge_dev", "/thebitforge_old"])
  end

  it "does not fail when user is missing" do
    expect do
      described_class.new.perform(User.maximum(:id).to_i + 1)
    end.not_to raise_error
  end
end
