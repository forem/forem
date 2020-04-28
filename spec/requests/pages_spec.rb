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
      expect(response.body).to include("About")
    end
  end

  describe "GET /about-listings" do
    it "has proper headline" do
      get "/about-listings"
      expect(response.body).to include("About #{ApplicationConfig['COMMUNITY_NAME']} Listings")
    end
  end

  describe "GET /community-moderation" do
    it "has proper headline" do
      get "/community-moderation"
      expect(response.body).to include("Community Moderation Guide")
    end
  end

  describe "GET /tag-moderation" do
    it "has proper headline" do
      get "/tag-moderation"
      expect(response.body).to include("Tag Moderation Guide")
    end
  end

  describe "GET /page/post-a-job" do
    it "has proper headline" do
      get "/page/post-a-job"
      expect(response.body).to include("Posting a Job on #{ApplicationConfig['COMMUNITY_NAME']} Listings")
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
      expect(response.body).to include(SiteConfig.shop_url)
      expect(response.body).to include("#{ApplicationConfig['COMMUNITY_NAME']} Shop")
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
      expect(response.body).to include("Reporting Vulnerabilities")
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

  describe "GET /checkin" do
    let_it_be(:user) { create(:user, username: "codenewbiestaff") }

    it "redirects to the latest CodeNewbie staff thread" do
      earlier_staff_thread = create(:article, user: user, tags: "staff")
      earlier_staff_thread.update(published_at: 1.week.ago)
      latest_staff_thread = create(:article, user: user, tags: "staff")
      get "/checkin"

      expect(response.body).to redirect_to(latest_staff_thread.path)
    end

    it "redirects to /notifications if there is no staff user post" do
      get "/checkin"

      expect(response.body).to redirect_to("/notifications")
    end
  end

  describe "GET /badge" do
    it "has proper headline" do
      html_variant = create(:html_variant, group: "badge_landing_page", published: true, approved: true)
      get "/badge"
      expect(response.body).to include(html_variant.html)
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
