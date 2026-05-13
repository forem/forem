require "rails_helper"

RSpec.describe "Custom Domain Redirects", type: :request do
  let!(:organization) { create(:organization, custom_domain: "blog.example.com") }
  
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

    it "raises ActiveRecord::RecordNotFound if no redirect exists" do
      host! "blog.example.com"
      
      expect {
        get "/non-existent-post"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not redirect if the domain does not match even if the path exists" do
      host! "other.example.com"
      
      expect {
        get "/my-old-post"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "bypasses the custom domain constraint and does not use custom domain routes for AJAX requests" do
      host! "blog.example.com"
      
      # Since we don't have a route for /my-old-post in standard routes,
      # it will raise RecordNotFound instead of redirecting because the constraint was bypassed.
      expect {
        get "/my-old-post", xhr: true
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "bypasses the custom domain constraint for JSON format requests" do
      host! "blog.example.com"
      
      expect {
        get "/my-old-post", as: :json
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "bypasses the custom domain constraint for requests with Sec-Fetch-Mode: cors" do
      host! "blog.example.com"
      
      expect {
        get "/my-old-post", headers: { "Sec-Fetch-Mode" => "cors" }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "bypasses the custom domain constraint for requests with Sec-Fetch-Dest: empty" do
      host! "blog.example.com"
      
      expect {
        get "/my-old-post", headers: { "Sec-Fetch-Dest" => "empty" }
      }.to raise_error(ActiveRecord::RecordNotFound)
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

    it "does not bypass the constraint if the request is AJAX but has ?i=i" do
      host! "blog.example.com"
      
      # Should redirect because i=i prevents the AJAX bypass
      get "/my-old-post", params: { i: "i" }, xhr: true
      
      expect(response).to redirect_to("https://dev.to/my-new-post")
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
