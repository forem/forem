require "rails_helper"

RSpec.describe "Custom Domain Redirects", type: :request do
  let!(:organization) { create(:organization, custom_domain: "blog.example.com") }

  before do
    allow(Settings::General).to receive(:app_domain).and_return("forem.com")
  end
  
  context "when the custom domain feature flag is enabled" do
    let!(:base_redirect) do
      RequestRedirect.create!(
        request_domain: "blog.example.com",
        original_url: "/my-old-post",
        destination_url: "https://dev.to/my-new-post"
      )
    end

    before do
      FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor.new(organization))
    end

    it "redirects to the destination url if a RequestRedirect exists for the path" do
      host! "blog.example.com"
      get "/my-old-post"
      
      expect(response).to redirect_to("https://dev.to/my-new-post")
      expect(response).to have_http_status(:moved_permanently)
    end

    it "prioritizes a fullpath match (with query string) over a path-only match" do
      RequestRedirect.create!(
        request_domain: "blog.example.com",
        original_url: "/my-old-post?ref=newsletter",
        destination_url: "https://dev.to/my-new-post-from-newsletter"
      )

      host! "blog.example.com"
      get "/my-old-post?ref=newsletter"
      
      expect(response).to redirect_to("https://dev.to/my-new-post-from-newsletter")
      expect(response).to have_http_status(:moved_permanently)
    end

    it "falls back to a path-only match if the query string doesn't match any specific rule" do
      host! "blog.example.com"
      get "/my-old-post?ref=twitter"
      
      # Should fall back to the path-only redirect because there's no rule for ?ref=twitter
      expect(response).to redirect_to("https://dev.to/my-new-post")
      expect(response).to have_http_status(:moved_permanently)
    end

    it "redirects to the main app domain if no redirect exists" do
      host! "blog.example.com"
      get "/non-existent-post"
      
      expect(response).to redirect_to("http://forem.com/non-existent-post")
      expect(response).to have_http_status(:moved_permanently)
    end

    it "redirects non-profile and non-article pages (like /enter) to the main app domain" do
      host! "blog.example.com"
      get "/enter"
      
      expect(response).to redirect_to("http://forem.com/enter")
      expect(response).to have_http_status(:moved_permanently)
    end

    it "redirects other valid global HTML pages (like /search) to the main app domain" do
      host! "blog.example.com"
      get "/search"
      
      expect(response).to redirect_to("http://forem.com/search")
      expect(response).to have_http_status(:moved_permanently)
    end

    it "does not redirect if the domain does not match even if the path exists" do
      host! "other.example.com"
      
      expect {
        get "/my-old-post"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "handles requests with Sec-Fetch-Dest: empty on custom domain paths" do
      host! "blog.example.com"
      get "/my-old-post", headers: { "Sec-Fetch-Dest" => "empty" }

      expect(response).to redirect_to("https://dev.to/my-new-post")
      expect(response).to have_http_status(:moved_permanently)
    end

    it "handles requests with Sec-Fetch-Mode: cors on custom domain paths" do
      host! "blog.example.com"
      get "/my-old-post", headers: { "Sec-Fetch-Mode" => "cors" }

      expect(response).to redirect_to("https://dev.to/my-new-post")
      expect(response).to have_http_status(:moved_permanently)
    end

    it "bypasses the custom domain constraint for /async_info paths" do
      host! "blog.example.com"
      
      # Since we bypassed the constraint, it hits the standard Forem routes
      expect {
        get "/async_info/base_data"
      }.not_to raise_error
    end

    it "bypasses the custom domain constraint for /reactions paths" do
      host! "blog.example.com"
      
      # Since we bypassed the constraint, it hits the standard Forem routes
      expect {
        get "/reactions"
      }.not_to raise_error
    end

    it "does not raise a DoubleRenderError and redirects successfully when org_slug is mismatched on show path" do
      host! "blog.example.com"
      
      get "/wrong-org/feed"
      
      expect(response).to redirect_to("http://forem.com/wrong-org/feed")
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  context "when the custom domain feature flag is disabled" do
    before do
      FeatureFlag.disable(:org_custom_domain, FeatureFlag::Actor.new(organization))
    end

    it "does not redirect and raises ActiveRecord::RecordNotFound" do
      host! "blog.example.com"
      
      expect {
        get "/my-old-post"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
