require "rails_helper"

RSpec.describe "/api/admin/users", type: :request do
  let(:params) { { email: "test@example.com" } }
  let(:v1_headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }

  context "when unauthorized" do
    it "rejects requests without an authorization token" do
      expect do
        post api_admin_users_path, params: params, headers: v1_headers
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with a non-admin token" do
      api_secret = create(:api_secret, user: create(:user))
      headers = v1_headers.merge({ "api-key" => api_secret.secret })

      expect do
        post api_admin_users_path, params: params, headers: headers
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with a regular admin token" do
      api_secret = create(:api_secret, user: create(:user, :admin))
      headers = v1_headers.merge({ "api-key" => api_secret.secret })

      expect do
        post api_admin_users_path, params: params, headers: headers
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when authorized" do
    let!(:super_admin) { create(:user, :super_admin) }
    let(:api_secret) { create(:api_secret, user: super_admin) }
    let(:headers) { v1_headers.merge({ "api-key" => api_secret.secret }) }

    it "accepts request with a super-admin token" do
      expect do
        post api_admin_users_path, params: params, headers: headers
      end.to change(User, :count).by(1)

      expect(response).to have_http_status(:ok)
    end
  end
end
