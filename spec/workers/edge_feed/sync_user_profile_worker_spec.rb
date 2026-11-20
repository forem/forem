require "rails_helper"

RSpec.describe EdgeFeed::SyncUserProfileWorker, type: :worker do
  let(:user) { create(:user, :without_profile, profile_image: nil) }
  let(:kv_client) { instance_double(EdgeFeed::KvClient, put: :written) }

  before do
    allow(EdgeFeed::KvClient).to receive_messages(configured?: true, new: kv_client)
  end

  it "does nothing when the :fastly_edge_feed_mirror feature flag is disabled" do
    FeatureFlag.disable(:fastly_edge_feed_mirror)

    described_class.new.perform(user.id)

    expect(kv_client).not_to have_received(:put)
  end

  it "mirrors user:<id> profile to Fastly KV when enabled" do
    FeatureFlag.enable(:fastly_edge_feed_mirror)

    described_class.new.perform(user.id)

    expect(kv_client).to have_received(:put).with(
      "user:#{user.id}",
      hash_including(user_id: user.id),
    )
  ensure
    FeatureFlag.disable(:fastly_edge_feed_mirror)
  end
end
