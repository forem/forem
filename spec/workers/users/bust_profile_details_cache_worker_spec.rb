require "rails_helper"

RSpec.describe Users::BustProfileDetailsCacheWorker, type: :worker do
  let(:user) { create(:user) }

  before do
    allow(EdgeCache::PurgeByKey).to receive(:call)
  end

  it "busts the profile details cache key" do
    described_class.new.perform(user.id)
    expect(EdgeCache::PurgeByKey).to have_received(:call).with(
      user.profile_details_record_key,
      fallback_paths: user.profile_cache_bust_paths,
    )
  end

  it "does not fail when user is missing" do
    expect do
      described_class.new.perform(User.maximum(:id).to_i + 1)
    end.not_to raise_error
  end
end
