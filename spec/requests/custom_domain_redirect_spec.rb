require "rails_helper"

RSpec.describe "Custom Domain Redirects", type: :request do
  let!(:organization) { create(:organization, custom_domain: "blog.example.com") }
  
  before do
    FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor.new(organization))

    # Create the request redirect
    RequestRedirect.create!(
      request_domain: "blog.example.com",
      original_url: "/my-old-post",
      destination_url: "https://dev.to/my-new-post"
    )
  end

  it "redirects to the destination url if a RequestRedirect exists" do
    # We need to simulate a request to the custom domain that causes a 404.
    # The route /my-old-post will fall through to ApplicationController#not_found
    # because it doesn't match any specific route for custom domains if we don't have a matching article.
    # Actually, /my-old-post might match get "/:slug" to "pages#show", which will then raise RecordNotFound.
    
    host! "blog.example.com"
    
    # Normally this would raise ActiveRecord::RecordNotFound, but our fallback catches it.
    get "/my-old-post"
    
    expect(response).to redirect_to("https://dev.to/my-new-post")
    expect(response).to have_http_status(:moved_permanently)
  end

  it "raises ActiveRecord::RecordNotFound if no redirect exists" do
    host! "blog.example.com"
    
    expect {
      get "/non-existent-post"
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "does not redirect if the domain does not match" do
    host! "other.example.com"
    
    expect {
      get "/my-old-post"
    }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
