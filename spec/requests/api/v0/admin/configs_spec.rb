require "rails_helper"

RSpec.describe "Api::V0::Admin::Configs", type: :request do
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }

  describe "GET /api/admin/config" do
    before do
      allow(SiteConfig).to receive(:community_name).and_return("ANYTHING")
      allow(SiteConfig).to receive(:all).and_return([SiteConfig.new(var: "community_name", value: "ANYTHING")])
    end

    context "when user is super admin" do
      before do
        user.add_role(:super_admin)
      end

      it "renders json when passed key" do
        headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
        get api_admin_config_path, headers: headers

        expect(response.parsed_body["community_name"]).to eq SiteConfig.community_name
      end

      it "renders json when signed in" do
        sign_in user
        get api_admin_config_path

        expect(response.parsed_body["community_name"]).to eq SiteConfig.community_name
      end
    end

    context "when user is not super admin" do
      it "renders unauthorized json" do
        headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
        get api_admin_config_path, headers: headers

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["error"]).to eq "unauthorized"
      end
    end

    context "when no user" do
      it "renders unauthorized json" do
        get api_admin_config_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
