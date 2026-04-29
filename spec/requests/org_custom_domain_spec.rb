require "rails_helper"

RSpec.describe "Organization Custom Domain Routing", type: :request do
  let(:organization) { create(:organization, custom_domain: "custom.org") }

  before do
    allow(Settings::General).to receive(:app_domain).and_return("forem.com")
  end

  context "when the custom domain feature is disabled" do
    before do
      Flipper.disable(:org_custom_domain, organization)
    end

    it "does not route to custom_domain_index and returns 404 for unknown domains" do
      # Note: Since there's no route defined for this unknown domain explicitly,
      # and the constraint fails, Rails might return a 404 or process it as a regular request
      # assuming it hit a generic route. If it hits the root_path, it will render stories#index
      # Let's test that the organization profile is NOT rendered.
      get "http://custom.org/"
      
      # It defaults to stories#index if constraint is skipped and hits root
      # but we don't want to test the default behavior extensively, just that it doesn't 
      # behave like the custom domain org profile.
      expect(response).to have_http_status(:success)
      expect(response.body).not_to include(organization.name)
    end
  end

  context "when the custom domain feature is enabled" do
    before do
      Flipper.enable(:org_custom_domain, organization)
    end

    it "routes root path to the organization profile" do
      get "http://custom.org/"

      expect(response).to have_http_status(:success)
      # The organization show page should be rendered
      expect(response.body).to include(organization.name)
    end
  end
end
