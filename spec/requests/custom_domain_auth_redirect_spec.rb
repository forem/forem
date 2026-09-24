require "rails_helper"

RSpec.describe "Custom Domain Iframe Auth Redirect", type: :request do
  let!(:organization) { create(:organization, slug: "mlh", custom_domain: "blog.mlh.com") }
  let(:user) { create(:user) }
  let!(:article) { create(:article, organization: organization, user: user, slug: "hackathon-guide", title: "Hackathon Guide") }

  before do
    allow(Settings::General).to receive(:app_domain).and_return("forem.com")
    FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor.new(organization))
    MemoryFirstCache.delete("org_custom_domain_id:#{organization.custom_domain}")
  end

  describe "rendered auth iframe script on custom domains" do
    context "when viewing custom domain root" do
      it "renders redirect script pointing to organization main domain profile" do
        get "http://blog.mlh.com/"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("auth_pass/iframe")
        expect(response.body).to include("http://forem.com/auth_pass/iframe")
        expect(response.body).to include("var redirectUrl = 'http://forem.com/mlh'")
        expect(response.body).to include("window.location.replace(redirectUrl)")
      end

      it "preserves query parameters in redirect script" do
        get "http://blog.mlh.com/?sort=top&page=2"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("var redirectUrl = 'http://forem.com/mlh?sort=top&page=2'")
        expect(response.body).to include("window.location.replace(redirectUrl)")
      end
    end

    context "when viewing custom domain article show" do
      it "renders redirect script pointing to main domain article URL" do
        get "http://blog.mlh.com/hackathon-guide"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("http://forem.com/auth_pass/iframe")
        expect(response.body).to include("var redirectUrl = 'http://forem.com/mlh/hackathon-guide'")
        expect(response.body).to include("window.location.replace(redirectUrl)")
      end
    end

    context "when viewing custom domain custom page" do
      let!(:custom_page) { create(:page, organization: organization, slug: "#{organization.slug}/about", body_markdown: "About MLH") }

      before do
        FeatureFlag.enable(:org_readme, FeatureFlag::Actor.new(organization))
      end

      it "renders redirect script pointing to main domain custom page URL" do
        get "http://blog.mlh.com/p/about"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("http://forem.com/auth_pass/iframe")
        expect(response.body).to include("var redirectUrl = 'http://forem.com/mlh/p/about'")
        expect(response.body).to include("window.location.replace(redirectUrl)")
      end
    end
  end

  describe "CORS and CSP for custom organization domains" do
    it "allows custom organization domain in CORS headers for AuthPassController" do
      token = JWT.encode({ user_id: user.id, exp: 5.minutes.from_now.to_i }, Rails.application.secret_key_base)

      post "/auth_pass/token_login",
           params: { token: token }.to_json,
           headers: { "Origin" => "https://blog.mlh.com", "Content-Type" => "application/json" }

      expect(response.headers["Access-Control-Allow-Origin"]).to eq("https://blog.mlh.com")
      expect(response.headers["Access-Control-Allow-Credentials"]).to eq("true")
    end

    it "sets dynamic per-request CSP frame-ancestors for valid custom domain on iframe endpoint" do
      get "http://forem.com/auth_pass/iframe?passed_domain=https://blog.mlh.com"

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Security-Policy"]).to eq("frame-ancestors 'self' https://blog.mlh.com")
    end

    it "does not include unauthorized origin in dynamic CSP on iframe endpoint" do
      get "http://forem.com/auth_pass/iframe?passed_domain=https://unauthorized-domain.com"

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Security-Policy"]).not_to include("unauthorized-domain.com")
    end
  end
end
