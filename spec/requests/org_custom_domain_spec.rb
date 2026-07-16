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

    describe "signed out redirection" do
      let(:user) { create(:user) }
      let!(:article) { create(:article, organization: organization, user: user, title: "Test Article Content") }

      it "does not redirect organization profile page requests" do
        get "http://forem.com/#{organization.slug}"
        expect(response).to have_http_status(:success)
      end

      it "does not redirect organization article requests" do
        get "http://forem.com/#{organization.slug}/#{article.slug}"
        expect(response).to have_http_status(:success)
      end
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

    it "redirects header links to the main app domain and styles the topbar with the organization brand color" do
      organization.update!(bg_color_hex: "#1ab394", text_color_hex: "#ffffff")

      get "http://custom.org/"

      expect(response).to have_http_status(:success)

      # 1. Logo links to main domain root
      expect(response.body).to match(/href="http:\/\/forem\.com\/?" class="site-logo"/)

      # 2. Search form action points to search on the main domain
      expect(response.body).to match(/action="http:\/\/forem\.com\/search"/)

      # 3. Signin / Signup links point to main domain enter page
      expect(response.body).to match(/href="http:\/\/forem\.com\/enter/)

      # 4. Topbar styling is added with the organization's custom background color
      expect(response.body).to include("#topbar { background: #1ab394 !important; }")
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

      it "redirects to the main app domain for articles not belonging to the organization" do
        other_article = create(:article)
        get "http://custom.org/#{other_article.slug}"

        expect(response).to redirect_to("http://forem.com/#{other_article.slug}")
        expect(response).to have_http_status(:moved_permanently)
      end
    end

    describe "feed routing" do
      let(:user) { create(:user) }
      let!(:article) { create(:article, organization: organization, user: user, title: "Org Article Title") }
      let!(:other_article) { create(:article, title: "Other Article Title") }

      it "routes /feed to the organization's feed, returning only organization articles" do
        get "http://custom.org/feed"

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/xml")
        expect(response.body).to include("Org Article Title")
        expect(response.body).not_to include("Other Article Title")

        expect(response.body).to include("<link>http://custom.org</link>")
        expect(response.body).to include("<link>http://custom.org/#{article.slug}</link>")
        expect(response.body).to include("<guid>http://custom.org/#{article.slug}</guid>")
      end

      it "routes /rss to the organization's feed, returning only organization articles" do
        get "http://custom.org/rss"

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/xml")
        expect(response.body).to include("Org Article Title")
        expect(response.body).not_to include("Other Article Title")

        expect(response.body).to include("<link>http://custom.org</link>")
        expect(response.body).to include("<link>http://custom.org/#{article.slug}</link>")
      end
    end

    describe "signed out redirection to custom domain" do
      let(:user) { create(:user) }
      let!(:article) { create(:article, organization: organization, user: user, title: "Test Article Content") }

      context "when user is not signed in" do
        it "redirects organization profile page requests on main domain to custom domain root" do
          get "http://forem.com/#{organization.slug}"
          expect(response).to redirect_to("http://custom.org/")
          expect(response).to have_http_status(:found)
        end

        it "preserves query parameters when redirecting organization profile page" do
          get "http://forem.com/#{organization.slug}?ref=newsletter&page=2"
          expect(response).to redirect_to("http://custom.org/?ref=newsletter&page=2")
          expect(response).to have_http_status(:found)
        end

        it "redirects organization article requests on main domain to custom domain with slug only" do
          get "http://forem.com/#{organization.slug}/#{article.slug}"
          expect(response).to redirect_to("http://custom.org/#{article.slug}")
          expect(response).to have_http_status(:found)
        end

        it "preserves query parameters when redirecting article page" do
          get "http://forem.com/#{organization.slug}/#{article.slug}?utm_source=twitter"
          expect(response).to redirect_to("http://custom.org/#{article.slug}?utm_source=twitter")
          expect(response).to have_http_status(:found)
        end
      end

      context "when user is signed in" do
        let(:logged_in_user) { create(:user) }

        before do
          sign_in logged_in_user
        end

        it "does not redirect organization profile page requests" do
          get "http://forem.com/#{organization.slug}"
          expect(response).to have_http_status(:success)
        end

        it "does not redirect organization article requests" do
          get "http://forem.com/#{organization.slug}/#{article.slug}"
          expect(response).to have_http_status(:success)
        end
      end
    end
  end
end
