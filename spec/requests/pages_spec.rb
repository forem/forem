require "rails_helper"

RSpec.describe "Pages" do
  describe "GET /:slug" do
    it "has proper headline for non-top-level" do
      page = create(:page, title: "Edna O'Brien96")
      get "/page/#{page.slug}"
      expect(response.body).to include(CGI.escapeHTML(page.title))
      expect(response.body).to include("/page/#{page.slug}")
    end

    it "has proper headline and classes for top-level" do
      page = create(:page, title: "Edna O'Brien96", is_top_level_path: true)
      get "/#{page.slug}"
      expect(response.body).to include(CGI.escapeHTML(page.title))
      expect(response.body).not_to include("/page/#{page.slug}")
      expect(response.body).to include("stories-show")
      expect(response.body).to include(" pageslug-#{page.slug}")
    end

    context "when json template" do
      let(:json_text) { "{\"foo\": \"bar\"}" }
      let(:page) do
        create(:page, title: "sample_data", template: "json", body_json: json_text, body_html: nil, body_markdown: nil)
      end

      before do
        page.save! # Trigger processing of page.body_html
      end

      it "returns json data" do
        get "/page/#{page.slug}"

        expect(response.media_type).to eq("application/json")
        expect(response.body).to include(json_text)
      end

      it "returns json data for top level template" do
        page.is_top_level_path = true
        page.save!
        get "/#{page.slug}"

        expect(response.media_type).to eq("application/json")
        expect(response.body).to include(json_text)
      end
    end
  end

  describe "GET /:slug.txt" do
    it "renders proper text file when template is txt" do
      page = create(:page, title: "Text page", body_html: "This is a test", template: "txt")
      get "/#{page.slug}.txt"
      expect(response.body).to include(page.processed_html)
      expect(response.media_type).to eq("text/plain")
    end

    it "renders not found when .txt request does not have txt template" do
      page = create(:page, title: "Text page", body_html: "This is a test", template: "contained")
      expect { get "/#{page.slug}.txt" }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET /slug/slug/slug/etc." do
    it "renders proper page when slug has one subdirectory" do
      page = create(:page, slug: "first-slug/second-slug", is_top_level_path: true)
      get "/#{page.slug}"
      expect(response.body).to include(CGI.escapeHTML(page.title))
    end

    it "renders proper page when slug has two subdirectories" do
      page = create(:page, slug: "first-slug/second-slug/third-slug", is_top_level_path: true)
      get "/#{page.slug}"
      expect(response.body).to include(CGI.escapeHTML(page.title))
    end

    it "renders proper page when slug has three subdirectories" do
      page = create(:page, slug: "first-slug/second-slug/third-slug/fourth-slug", is_top_level_path: true)
      get "/#{page.slug}"
      expect(response.body).to include(CGI.escapeHTML(page.title))
    end

    it "renders proper page when slug has four subdirectories" do
      page = create(:page, slug: "first-slug/second-slug/third-slug/fourth-slug/fifth-slug", is_top_level_path: true)
      get "/#{page.slug}"
      expect(response.body).to include(CGI.escapeHTML(page.title))
    end

    it "renders proper page when slug has five subdirectories" do
      page = create(:page, slug: "first-slug/second-slug/third-slug/fourth-slug/fifth-slug/sixth-slug",
                           is_top_level_path: true)
      get "/#{page.slug}"
      expect(response.body).to include(CGI.escapeHTML(page.title))
    end

    it "returns not found when five directories, but no page" do
      # 6+ directories will be a non-valid page, so just further testing routing error
      expect { get "/heyhey/hey/hey/hey/hey" }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns routing error when 7+ directories" do
      # 6+ directories will be a non-valid page, so just further testing routing error
      expect { get "/heyhey/hey/hey/hey/hey/hey/hey" }.to raise_error(ActionController::RoutingError)
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
      expect(response.body).to include("About #{Settings::Community.community_name} Listings")
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
      expect(response.body).to include("Posting a Job on #{Settings::Community.community_name} Listings")
    end
  end

  describe "GET /api" do
    it "redirects to the API docs" do
      get "/api"
      expect(response.body).to redirect_to("https://developers.forem.com/api")
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
      expect(response.body).to include("Reporting Vulnerabilities")
    end
  end

  describe "GET /code-of-conduct" do
    it "has proper headline" do
      get "/code-of-conduct"
      expect(response.body).to include("Code of Conduct")
    end
  end

  describe "GET /contact" do
    it "has proper headline" do
      get "/contact"
      expect(response.body).to include("Contact")
      expect(response.body).to include("@#{Settings::General.social_media_handles['twitter']}")
    end
  end

  describe "GET /welcome" do
    let(:user) { create(:user, id: 1) }

    it "redirects to the latest welcome thread" do
      earlier_welcome_thread = create(:article, user: user, tags: "welcome")
      earlier_welcome_thread.update(published_at: 1.week.ago)
      latest_welcome_thread = create(:article, user: user, tags: "welcome")
      get "/welcome"

      expect(response.body).to redirect_to(latest_welcome_thread.path)
    end

    context "when no welcome thread exists" do
      it "redirects to the notifications page" do
        get "/welcome"

        expect(response.body).to redirect_to(notifications_path)
      end
    end

    context "when the welcome thread has an absolute URL stored as its path" do
      it "redirects to a page on the same domain as the app" do
        vulnerable_welcome_thread = create(:article, user: user, tags: "welcome")
        vulnerable_welcome_thread.update_column(:path, "https://attacker.com/hijacked/welcome")

        get "/welcome"

        expect(response.body).to redirect_to("/hijacked/welcome")
      end
    end
  end

  describe "GET /challenge" do
    let(:user) { create(:user, id: 1) }

    it "redirects to the latest challenge thread" do
      earlier_challenge_thread = create(:article, user: user, tags: "challenge")
      earlier_challenge_thread.update(published_at: 1.week.ago)
      latest_challenge_thread = create(:article, user: user, tags: "challenge")
      get "/challenge"

      expect(response.body).to redirect_to(latest_challenge_thread.path)
    end

    context "when no challenge thread exists" do
      it "redirects to the notifications page" do
        get "/challenge"

        expect(response.body).to redirect_to(notifications_path)
      end
    end

    context "when the challenge thread has an absolute URL stored as its path" do
      it "redirects to a page on the same domain as the app" do
        vulnerable_challenge_thread = create(:article, user: user, tags: "challenge")
        vulnerable_challenge_thread.update_column(:path, "https://attacker.com/hijacked/challenge")

        get "/challenge"

        expect(response.body).to redirect_to("/hijacked/challenge")
      end
    end
  end

  describe "GET /checkin" do
    let(:user) { create(:user, username: "codenewbiestaff") }

    it "redirects to the latest CodeNewbie staff thread" do
      earlier_staff_thread = create(:article, user: user, tags: "staff")
      earlier_staff_thread.update(published_at: 1.week.ago)
      latest_staff_thread = create(:article, user: user, tags: "staff")
      get "/checkin"

      expect(response.body).to redirect_to(latest_staff_thread.path)
    end

    context "when there is no staff user post" do
      it "redirects to the notifications page" do
        get "/checkin"

        expect(response.body).to redirect_to(notifications_path)
      end
    end

    context "when the staff thread has an absolute URL stored as its path" do
      it "redirects to a page on the same domain as the app" do
        vulnerable_staff_thread = create(:article, user: user, tags: "staff")
        vulnerable_staff_thread.update_column(:path, "https://attacker.com/hijacked/staff")

        get "/checkin"

        expect(response.body).to redirect_to("/hijacked/staff")
      end
    end
  end

  describe "GET /robots.txt" do
    it "has proper text" do
      get "/robots.txt"

      text = "Sitemap: #{URL.url('sitemap-index.xml')}"
      expect(response.body).to include(text)
    end
  end

  describe "GET /report-abuse" do
    context "when provided the referer" do
      it "prefills with the provided url" do
        url = Faker::Internet.url
        get "/report-abuse", headers: { referer: url }
        expect(response.body).to include(url)
      end
    end
  end
end
