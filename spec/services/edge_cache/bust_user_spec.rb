require "rails_helper"

RSpec.describe EdgeCache::BustUser, type: :service do
  let(:user) { create(:user) }

  before do
    allow(EdgeCache::PurgeByKey).to receive(:call)
  end

  it "busts the cache" do
    described_class.call(user)
    expect(EdgeCache::PurgeByKey).to have_received(:call).with(
      user.profile_cache_keys,
      fallback_paths: user.profile_cache_bust_paths,
    )
  end
end
