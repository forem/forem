require "rails_helper"

RSpec.describe "Organization Custom Domain Routing", type: :request do
  let(:organization) { create(:organization, custom_domain: "custom.org") }

  before do
    allow(Settings::General).to receive(:app_domain).and_return("forem.com")
  end

  context "when the custom domain feature is disabled" do
    before do
      FeatureFlag.disable(:org_custom_domain, FeatureFlag::Actor.new(organization))
    end

    it "falls back to the default root behavior instead of rendering the organization profile" do
      # With the feature disabled, the custom domain request should not be handled
      # as the organization's custom-domain root route.
      get "http://custom.org/"

      # The request falls through to the normal root handling, so we assert that
      # it succeeds but does not render the organization profile content.
      expect(response).to have_http_status(:success)
      expect(response.body).not_to include(organization.name)
    end
  end

  context "when the custom domain feature is enabled" do
    before do
      FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor.new(organization))
    end

    it "routes root path to the organization profile" do
      get "http://custom.org/"

      expect(response).to have_http_status(:success)
      # The organization show page should be rendered
      expect(response.body).to include(organization.name)
    end

    describe "API routing" do
      it "does not intercept /api endpoints on a custom domain" do
        get "http://custom.org/api/articles"
        # Assuming the API route exists and returns 200 or 4xx, but not a 404 from the custom domain catch-all
        # Assert the request was routed through the API controller/action
        # rather than being intercepted by the custom-domain root handling.
        expect(request.path_parameters[:controller]).to eq("api/v0/articles")
        expect(request.path_parameters[:action]).to eq("index")
      end
    end

    describe "article routing" do
      let(:user) { create(:user) }
      let!(:article) { create(:article, organization: organization, user: user, title: "Test Article Content") }

      it "routes /:slug to the organization's article" do
        get "http://custom.org/#{article.slug}"

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Test Article Content")
      end

      it "routes /:username/:slug to the organization's article" do
        get "http://custom.org/#{organization.slug}/#{article.slug}"

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Test Article Content")
      end

      it "returns 404 for articles not belonging to the organization" do
        other_article = create(:article)
        expect {
          get "http://custom.org/#{other_article.slug}"
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
