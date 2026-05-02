require "rails_helper"

RSpec.describe "Api::V1::Admin::UserIdentities", type: :request do
  before { Audit::Subscribe.listen :admin_api }
  after  { Audit::Subscribe.forget :admin_api }

  let!(:user) { create(:user) }

  describe "GET /api/admin/users/:user_id/identities" do
    it "returns identities without leaking secrets" do
      omniauth_mock_mlh_payload if defined?(omniauth_mock_mlh_payload)
      identity = create(:identity, user: user, provider: "mlh", uid: "core-1",
                                   token: "topsecret", secret: "alsosecret")

      get "/api/admin/users/#{user.id}/identities", headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      payload = response.parsed_body["identities"].first
      expect(payload).to include("id" => identity.id, "provider" => "mlh", "uid" => "core-1")
      expect(payload.keys).not_to include("token", "secret", "auth_data_dump")
    end

    it "returns [] for users without identities" do
      get "/api/admin/users/#{user.id}/identities", headers: admin_api_headers
      expect(response.parsed_body["identities"]).to eq([])
    end

    it "404s for missing user" do
      get "/api/admin/users/999999/identities", headers: admin_api_headers
      expect(response).to have_http_status(:not_found)
    end

    it "401s without api key" do
      get "/api/admin/users/#{user.id}/identities",
          headers: { "Accept" => "application/vnd.forem.api-v1+json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/admin/users/:user_id/identities" do
    it "creates a new identity (state 1: clean)" do
      omniauth_mock_mlh_payload if defined?(omniauth_mock_mlh_payload)
      expect {
        post "/api/admin/users/#{user.id}/identities",
             params: { provider: "mlh", uid: "core-12345" }, headers: admin_api_headers
      }.to change { user.reload.identities.count }.by(1)

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body).to include("provider" => "mlh", "uid" => "core-12345")
    end

    it "is idempotent for the same (user, provider, uid) (state 2)" do
      omniauth_mock_mlh_payload if defined?(omniauth_mock_mlh_payload)
      create(:identity, user: user, provider: "mlh", uid: "core-12345")

      expect {
        post "/api/admin/users/#{user.id}/identities",
             params: { provider: "mlh", uid: "core-12345" }, headers: admin_api_headers
      }.not_to change { Identity.count }

      expect(response).to have_http_status(:ok)
    end

    it "409s when user has different uid for same provider (state 3)" do
      omniauth_mock_mlh_payload if defined?(omniauth_mock_mlh_payload)
      create(:identity, user: user, provider: "mlh", uid: "core-old")

      post "/api/admin/users/#{user.id}/identities",
           params: { provider: "mlh", uid: "core-new" }, headers: admin_api_headers

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error_code"]).to eq("user_already_has_identity_for_provider")
    end

    it "409s when (provider, uid) is already linked elsewhere (state 4)" do
      omniauth_mock_mlh_payload if defined?(omniauth_mock_mlh_payload)
      other = create(:user)
      create(:identity, user: other, provider: "mlh", uid: "core-shared")

      post "/api/admin/users/#{user.id}/identities",
           params: { provider: "mlh", uid: "core-shared" }, headers: admin_api_headers

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error_code"]).to eq("identity_uid_taken")
    end

    it "422s on unknown provider" do
      post "/api/admin/users/#{user.id}/identities",
           params: { provider: "doesnotexist", uid: "x" }, headers: admin_api_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error_code"]).to eq("unknown_provider")
    end

    it "sets user.<provider>_username when 'username' param is provided" do
      omniauth_mock_mlh_payload if defined?(omniauth_mock_mlh_payload)
      post "/api/admin/users/#{user.id}/identities",
           params: { provider: "mlh", uid: "core-12345", username: "jane_mlh" },
           headers: admin_api_headers

      expect(user.reload.mlh_username).to eq("jane_mlh")
    end

    it "audits the link" do
      omniauth_mock_mlh_payload if defined?(omniauth_mock_mlh_payload)
      expect {
        post "/api/admin/users/#{user.id}/identities",
             params: { provider: "mlh", uid: "audited" }, headers: admin_api_headers
      }.to change(AuditLog, :count).by(1)

      audit = AuditLog.last
      expect(audit.slug).to eq("link_identity")
      expect(audit.data).to include("provider" => "mlh", "uid" => "audited", "target_user_id" => user.id)
    end
  end
end
