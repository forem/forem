require "rails_helper"

RSpec.describe "Token authentication security" do
  let(:user) { create(:user) }
  let(:mobile_token) { Authentication::AuthToken.encode_mobile_api(user) }
  let(:legacy_mobile_token) do
    JWT.encode({ user_id: user.id, exp: 30.days.from_now.to_i }, Rails.application.secret_key_base, "HS256")
  end

  before do
    create(:notification, user: user, read: false)
  end

  describe "GET /notifications/counts" do
    it "does not accept a JWT passed via the ?jwt= query parameter" do
      get "/notifications/counts", params: { jwt: mobile_token }

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("0")
    end

    it "authenticates a valid mobile Bearer token in the Authorization header" do
      get "/notifications/counts", headers: { "Authorization" => "Bearer #{mobile_token}" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("1")
    end

    it "continues to accept legacy pre-deploy mobile Bearer tokens when user has not signed out" do
      get "/notifications/counts", headers: { "Authorization" => "Bearer #{legacy_mobile_token}" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("1")
    end

    it "rejects an auth_pass token sent as a Bearer API token" do
      auth_pass_token = Authentication::AuthToken.encode_auth_pass(user)

      get "/notifications/counts", headers: { "Authorization" => "Bearer #{auth_pass_token}" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("0")
    end

    it "invalidates mobile Bearer tokens when the user changes their password" do
      token = mobile_token
      user.update!(password: "NewSecurePassword123!", password_confirmation: "NewSecurePassword123!")

      get "/notifications/counts", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("0")
    end

    it "invalidates legacy pre-deploy mobile Bearer tokens when the user changes their password" do
      memory_store = ActiveSupport::Cache::MemoryStore.new
      allow(Rails).to receive(:cache).and_return(memory_store)

      token = legacy_mobile_token
      user.update!(password: "NewSecurePassword123!", password_confirmation: "NewSecurePassword123!")

      get "/notifications/counts", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("0")
    end

    it "invalidates mobile Bearer tokens when the user signs out and allows a new token issued afterward" do
      memory_store = ActiveSupport::Cache::MemoryStore.new
      allow(Rails).to receive(:cache).and_return(memory_store)

      old_token = mobile_token
      legacy_token = legacy_mobile_token

      Timecop.travel(Time.current + 0.05) do
        sign_in user
        delete destroy_user_session_path
        expect(Authentication::AuthToken.revoked_at_ms_for(user.id)).to be_present
        sign_out user
      end

      get "/notifications/counts", headers: { "Authorization" => "Bearer #{old_token}" }
      expect(response.body).to eq("0")

      get "/notifications/counts", headers: { "Authorization" => "Bearer #{legacy_token}" }
      expect(response.body).to eq("0")

      # Even within the same wall-clock second, a fresh token issued after sign-in works
      Timecop.travel(Time.current + 0.1) do
        user.update_columns(current_sign_in_at: Time.current)
        fresh_token = Authentication::AuthToken.encode_mobile_api(user)

        get "/notifications/counts", headers: { "Authorization" => "Bearer #{fresh_token}" }
        expect(response.body).to eq("1")
      end
    end

    it "rejects Bearer tokens when the user account is locked" do
      token = mobile_token
      user.update_column(:locked_at, Time.current)

      get "/notifications/counts", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("0")
    end
  end

  describe "POST /feed_events (ForemApp FeedTracker compatibility & URL JWT rejection)" do
    let(:article) { create(:article) }
    let(:event_params) do
      {
        article_id: article.id,
        article_position: 1,
        category: "click",
        context_type: FeedEvent::CONTEXT_TYPE_HOME
      }
    end

    around do |example|
      previous_store = Rack::Attack.cache.store
      Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
      example.run
    ensure
      Rack::Attack.cache.store = previous_store
    end

    it "authenticates a mobile JWT sent in the POST JSON body (ForemApp FeedTracker)" do
      expect do
        post "/feed_events",
             params: { feed_events: [event_params], jwt: mobile_token }.to_json,
             headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
      end.to change(FeedEvent, :count).by(1)

      expect(response).to be_successful
      expect(article.feed_events.last.user_id).to eq(user.id)
    end

    it "does not authenticate a JWT passed via the URL query string on POST /feed_events" do
      expect do
        post "/feed_events?jwt=#{mobile_token}",
             params: { feed_events: [event_params] }.to_json,
             headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
      end.not_to change(FeedEvent, :count)
    end

    it "does not authenticate an auth_pass token in the POST JSON body" do
      auth_pass_token = Authentication::AuthToken.encode_auth_pass(user)

      expect do
        post "/feed_events",
             params: { feed_events: [event_params], jwt: auth_pass_token }.to_json,
             headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
      end.not_to change(FeedEvent, :count)
    end

    it "rejects a revoked mobile JWT in the POST JSON body after password change" do
      token = mobile_token
      user.update!(password: "NewSecurePassword123!", password_confirmation: "NewSecurePassword123!")

      expect do
        post "/feed_events",
             params: { feed_events: [event_params], jwt: token }.to_json,
             headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
      end.not_to change(FeedEvent, :count)
    end
  end
end
