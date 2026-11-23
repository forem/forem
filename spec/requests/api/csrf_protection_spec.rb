require "rails_helper"

RSpec.describe "API CSRF protection" do
  let(:v1_headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }

  around do |example|
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  def fetch_csrf_token_for(signed_in_user)
    sign_in signed_in_user
    get "/async_info/base_data", headers: { "Accept" => "application/json" }
    response.parsed_body["token"]
  end

  describe "Api::V1 cookie-authenticated endpoints" do
    let(:user) { create(:user) }
    let(:target_user) { create(:user) }
    let(:api_secret) { create(:api_secret, user: user) }

    it "rejects cookie-authenticated POST /api/follows without a CSRF token" do
      sign_in user

      post api_follows_path,
           params: { user_ids: [target_user.id] },
           headers: v1_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not let an invalid api-key header bypass CSRF for a cookie-authenticated request" do
      sign_in user

      post api_follows_path,
           params: { user_ids: [target_user.id] },
           headers: v1_headers.merge("api-key" => "invalid-key")

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects mixed-credential POST /api/follows (distinct session and API-key users) without a CSRF token" do
      api_actor = create(:user)
      api_actor_secret = create(:api_secret, user: api_actor)
      allow(Users::FollowWorker).to receive(:perform_async)
      sign_in user

      post api_follows_path,
           params: { user_ids: [target_user.id] },
           headers: v1_headers.merge("api-key" => api_actor_secret.secret)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Users::FollowWorker).not_to have_received(:perform_async)
    end

    it "allows cookie-authenticated POST /api/follows with a valid CSRF token" do
      allow(Users::FollowWorker).to receive(:perform_async)
      csrf_token = fetch_csrf_token_for(user)

      post api_follows_path,
           params: { user_ids: [target_user.id] },
           headers: v1_headers.merge("X-CSRF-Token" => csrf_token),
           as: :json

      expect(response).to have_http_status(:ok)
      expect(Users::FollowWorker).to have_received(:perform_async).with(user.id, target_user.id, "User")
    end

    it "rejects cookie-authenticated V1 admin writes even when current_user is overridden" do
      super_admin = create(:user, :super_admin)
      sign_in super_admin

      expect do
        post api_admin_user_notes_path(user_id: target_user.id),
             params: { content: "CSRF note" },
             headers: v1_headers
      end.not_to change(Note, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "allows API-key authenticated POST /api/follows without a CSRF token" do
      post api_follows_path,
           params: { user_ids: [target_user.id] },
           headers: v1_headers.merge("api-key" => api_secret.secret)

      expect(response).to have_http_status(:ok)
    end

    it "returns 401 JSON for unauthenticated POST /api/follows without a CSRF token" do
      post api_follows_path,
           params: { user_ids: [target_user.id] },
           headers: v1_headers

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "Api::V0 cookie-authenticated endpoints" do
    let(:super_admin) { create(:user, :super_admin) }
    let(:api_secret) { create(:api_secret, user: super_admin) }

    it "rejects cookie-authenticated POST /api/admin/users without a CSRF token" do
      sign_in super_admin

      expect do
        post api_admin_users_path, params: { email: "invited-csrf@example.com" }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not let an invalid api-key header bypass CSRF on POST /api/admin/users" do
      sign_in super_admin

      expect do
        post api_admin_users_path,
             params: { email: "invited-csrf-bypass@example.com" },
             headers: { "api-key" => "invalid-key" }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "allows cookie-authenticated POST /api/admin/users with a valid CSRF token" do
      csrf_token = fetch_csrf_token_for(super_admin)

      expect do
        post api_admin_users_path,
             params: { email: "invited-csrf-valid@example.com" },
             headers: { "X-CSRF-Token" => csrf_token }
      end.to change(User, :count).by(1)

      expect(response).to have_http_status(:ok)
    end

    it "allows API-key authenticated POST /api/admin/users without a CSRF token" do
      secret = api_secret.secret

      expect do
        post api_admin_users_path,
             params: { email: "invited-api-key@example.com" },
             headers: { "api-key" => secret }
      end.to change(User, :count).by(1)

      expect(response).to have_http_status(:ok)
    end

    it "preserves default CSRF verification on V0 controllers that did not skip it" do
      target_user = create(:user)
      secret = api_secret.secret

      post api_follows_path,
           params: { user_ids: [target_user.id] },
           headers: { "api-key" => secret }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "allows on-site onboarding POST /api/follows with a valid CSRF token" do
      target_user = create(:user)
      allow(Users::FollowWorker).to receive(:perform_async)
      csrf_token = fetch_csrf_token_for(super_admin)

      post api_follows_path,
           params: { users: [{ id: target_user.id }] },
           headers: { "X-CSRF-Token" => csrf_token },
           as: :json

      expect(response).to have_http_status(:ok)
      expect(Users::FollowWorker).to have_received(:perform_async).with(super_admin.id, target_user.id, "User")
    end

    it "returns 401 JSON for unauthenticated POST /api/admin/users without a CSRF token" do
      expect do
        post api_admin_users_path, params: { email: "invited-unauth@example.com" }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects cookie-authenticated POST /api/articles without a CSRF token" do
      sign_in super_admin

      expect do
        post api_articles_path, params: { article: { title: "CSRF Test", body_markdown: "Hello" } }
      end.not_to change(Article, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "allows API-key authenticated POST /api/articles without a CSRF token" do
      secret = api_secret.secret

      expect do
        post api_articles_path,
             params: { article: { title: "API Key Article", body_markdown: "Hello" } },
             headers: { "api-key" => secret }
      end.to change(Article, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "rejects cookie-authenticated POST /api/events without a CSRF token" do
      sign_in super_admin

      expect do
        post api_events_path,
             params: {
               event: {
                 title: "CSRF Event",
                 event_name_slug: "csrf-event",
                 event_variation_slug: "v1",
                 start_time: 1.day.from_now,
                 end_time: 2.days.from_now,
                 type_of: "live_stream"
               }
             }
      end.not_to change(Event, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "allows API-key authenticated POST /api/events without a CSRF token" do
      secret = api_secret.secret

      expect do
        post api_events_path,
             params: {
               event: {
                 title: "API Event",
                 event_name_slug: "api-event",
                 event_variation_slug: "v1",
                 start_time: 1.day.from_now,
                 end_time: 2.days.from_now,
                 type_of: "live_stream"
               }
             },
             headers: { "api-key" => secret }
      end.to change(Event, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "rejects cookie-authenticated POST /api/badges without a CSRF token" do
      sign_in super_admin

      expect do
        post api_badges_path, params: { title: "CSRF Badge", description: "Test" }
      end.not_to change(Badge, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects cookie-authenticated POST /api/badge_achievements without a CSRF token" do
      badge = create(:badge)
      recipient = create(:user)
      sign_in super_admin

      expect do
        post api_badge_achievements_path,
             params: { username: recipient.username, badge_slug: badge.slug }
      end.not_to change(BadgeAchievement, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
