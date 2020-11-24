require "rails_helper"

RSpec.describe "Api::V0::Admin::Configs", type: :request do
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }

  describe "GET /api/admin/configs/all" do
    before do
      SiteConfig.community_name = "ANYTHING"
    end

    context "when user is super admin" do
      before do
        user.add_role(:super_admin)
      end

      it "renders json when passed key" do
        headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
        get "/api/admin/configs/all", headers: headers

        expect(response.parsed_body["community_name"]).to eq SiteConfig.community_name
      end

      it "renders json when signed in" do
        sign_in user
        get "/api/admin/configs/all"

        expect(response.parsed_body["community_name"]).to eq SiteConfig.community_name
      end
    end

    context "when user is not super admin" do
      it "renders unauthorized json" do
        headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
        get "/api/admin/configs/all", headers: headers

        expect(response.status).to eq 401
        expect(response.parsed_body["error"]).to eq "unauthorized"
      end
    end

    context "when no user" do
      it "renders unauthorized json" do
        get "/api/admin/configs/all"
        expect(response.status).to eq 401
      end
    end
  end
end
