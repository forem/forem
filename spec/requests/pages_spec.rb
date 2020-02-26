require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /:slug" do
    it "has proper headline for non-top-level" do
      page = create(:page, title: "Edna O'Brien96")
      get "/page/#{page.slug}"
      expect(response.body).to include(CGI.escapeHTML(page.title))
      expect(response.body).to include("/page/#{page.slug}")
    end

    it "has proper headline for top-level" do
      page = create(:page, title: "Edna O'Brien96", is_top_level_path: true)
      get "/#{page.slug}"
      expect(response.body).to include(CGI.escapeHTML(page.title))
      expect(response.body).not_to include("/page/#{page.slug}")
      expect(response.body).to include("stories-show")
    end
  end

  describe "GET /about" do
    it "has proper headline" do
      get "/about"
      expect(response.body).to include("About dev.to")
    end
  end

  describe "GET /api" do
    it "redirects to the API docs" do
      get "/api"
      expect(response.body).to redirect_to("https://docs.dev.to/api")
    end
  end

  describe "GET /privacy" do
    it "has proper headline" do
      get "/privacy"
      expect(response.body).to include("Privacy Policy")
    end
  end

  describe "GET /terms" do
    it "has proper headline" do
      get "/terms"
      expect(response.body).to include("Web Site Terms and Conditions of Use")
    end
  end

  describe "GET /security" do
    it "has proper headline" do
      get "/security"
      expect(response.body).to include("Reporting Vulnerabilities to dev.to")
    end
  end

  describe "GET /code-of-conduct" do
    it "has proper headline" do
      get "/code-of-conduct"
      expect(response.body).to include("Code of Conduct")
    end
  end

  describe "GET /rly" do
    it "has proper headline" do
      get "/rly"
      expect(response.body).to include("O RLY Cover Generator")
    end
  end

  describe "GET /sponsorship-info" do
    it "has proper headline" do
      get "/sponsorship-info"
      expect(response.body).to include("Sponsorship Information")
    end
  end

  describe "GET /welcome" do
    it "redirects to the latest welcome thread" do
      user = create(:user, id: 1)
      earlier_welcome_thread = create(:article, user: user, tags: "welcome")
      earlier_welcome_thread.update(published_at: Time.current - 1.week)
      latest_welcome_thread = create(:article, user: user, tags: "welcome")
      get "/welcome"

      expect(response.body).to redirect_to(latest_welcome_thread.path)
    end
  end

  describe "GET /challenge" do
    it "redirects to the latest challenge thread" do
      user = create(:user, id: 1)
      earlier_challenge_thread = create(:article, user: user, tags: "challenge")
      earlier_challenge_thread.update(published_at: Time.current - 1.week)
      latest_challenge_thread = create(:article, user: user, tags: "challenge")
      get "/challenge"

      expect(response.body).to redirect_to(latest_challenge_thread.path)
    end
  end

  describe "GET /badge" do
    it "has proper headline" do
      html_variant = create(:html_variant, group: "badge_landing_page", published: true, approved: true)
      get "/badge"
      expect(response.body).to include(html_variant.html)
    end
  end

  describe "GET /live" do
    context "when nothing is live" do
      it "shows the correct message" do
        get "/live"
        expect(response.body).to include("We are working on more ways to bring live coding to the community")
      end
    end
  end

  describe "GET /robots.txt" do
    it "has proper text" do
      get "/robots.txt"
      expect(response.body).to include("Sitemap: https://#{ApplicationConfig['AWS_BUCKET_NAME']}.s3.amazonaws.com/sitemaps/sitemap.xml.gz")
    end
  end

  describe "GET /report-abuse" do
    context "when provided the referer" do
      it "prefills with the provided url" do
        url = Faker::Internet.url
        get "/report-abuse", headers: { referer: url }
        expect(response.body).to include(url)
      end

      it "does not prefill if the provide url is /serviceworker.js" do
        url = "https://dev.to/serviceworker.js"
        get "/report-abuse", headers: { referer: url }
        expect(response.body).not_to include(url)
      end
    end

    context "when provided the params" do
      it "prefills with the provided param url" do
        url = "https://dev.to/serviceworker.js"
        get "/report-abuse", params: { url: url }
        expect(response.body).to include(url)
      end
    end
  end
end
