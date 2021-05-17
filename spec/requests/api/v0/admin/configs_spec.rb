require "rails_helper"

RSpec.xdescribe "Api::V0::Admin::Configs", type: :request do
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

        expect(response.parsed_body["community_name"]).to eq Settings::Community.community_name
      end

      it "renders json when signed in" do
        sign_in user
        get api_admin_config_path

        expect(response.parsed_body["community_name"]).to eq Settings::Community.community_name
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

  describe "PUT /api/admin/config" do
    context "when user is super admin" do
      let(:headers) { { "api-key" => api_secret.secret, "content-type" => "application/json" } }

      before do
        user.add_role(:super_admin)
      end

      it "Modifies SiteConfig data" do
        put api_admin_config_path, params: { site_config: { community_name: "new" } }.to_json, headers: headers

        expect(Settings::Community.community_name).to eq "new"
      end

      it "enables proper domains to allow list" do
        proper_list = "dev.to, forem.com, forem.dev"
        put api_admin_config_path, params: {
          site_config: { allowed_registration_email_domains: proper_list }
        }.to_json,
                                   headers: headers
        expect(Settings::Authentication.allowed_registration_email_domains).to eq(%w[dev.to forem.com forem.dev])
      end

      it "does not allow improper domain list" do
        improper_list = "dev.to, foremcom, forem.dev"
        put api_admin_config_path,
            params: { site_config: { allowed_registration_email_domains: improper_list } }.to_json,
            headers: headers
        expect(Settings::Authentication.allowed_registration_email_domains).not_to eq(%w[dev.to foremcom forem.dev])
      end

      it "removes space suggested_tags" do
        put api_admin_config_path, params: { site_config: { suggested_tags: "hey, haha,hoho, bobo fofo" } }.to_json,
                                   headers: headers
        expect(SiteConfig.suggested_tags).to eq(%w[hey haha hoho bobofofo])
      end

      it "downcases suggested_tags" do
        put api_admin_config_path, params: { site_config: { suggested_tags: "hey, haha,hoHo, Bobo Fofo" } }.to_json,
                                   headers: headers
        expect(SiteConfig.suggested_tags).to eq(%w[hey haha hoho bobofofo])
      end

      it "Renders siteconfig result" do
        put api_admin_config_path, params: { site_config: { community_name: "new" } }.to_json,
                                   headers: headers

        expect(response.parsed_body["community_name"]).to eq Settings::Community.community_name
      end
    end
  end
end
