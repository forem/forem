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
end
