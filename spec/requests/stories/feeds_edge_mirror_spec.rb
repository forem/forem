require "rails_helper"

RSpec.describe "Stories::FeedsController edge mirror warmup" do
  let(:user) { create(:user, :without_profile, profile_image: nil) }
  let(:secret) { "edge-request-test-secret" }

  before do
    sign_in user
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_EDGE_FEED_SECRET").and_return(secret)
    allow(EdgeFeed::KvClient).to receive(:configured?).and_return(true)
    allow(EdgeFeed::SyncUserProfileWorker).to receive(:perform_async)
  end

  it "sets the signed edge user cookie and enqueues profile sync on X-Forem-Edge-Miss: user-profile" do
    FeatureFlag.enable(:fastly_edge_feed_mirror)

    get "/stories/feed/",
        params: { page: 1, type_of: "discover" },
        headers: { "Accept" => "application/json", "X-Forem-Edge-Miss" => "user-profile" }

    expect(response).to have_http_status(:ok)
    expect(EdgeFeed::SyncUserProfileWorker).to have_received(:perform_async).with(user.id)
    cookie_val = response.cookies[EdgeFeed::TokenSigner::USER_COOKIE_NAME.to_s]
    expect(EdgeFeed::TokenSigner.verify_user_token(cookie_val)).to eq(user.id)
  ensure
    FeatureFlag.disable(:fastly_edge_feed_mirror)
  end

  it "does not set edge cookies or enqueue profile sync when the feature flag is disabled" do
    FeatureFlag.disable(:fastly_edge_feed_mirror)

    get "/stories/feed/",
        params: { page: 1, type_of: "discover" },
        headers: { "Accept" => "application/json", "X-Forem-Edge-Miss" => "user-profile" }

    expect(response).to have_http_status(:ok)
    expect(EdgeFeed::SyncUserProfileWorker).not_to have_received(:perform_async)
    expect(response.cookies[EdgeFeed::TokenSigner::USER_COOKIE_NAME.to_s]).to be_nil
  end
end
