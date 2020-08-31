require "rails_helper"

RSpec.shared_examples "redirects to the lowercase route" do
  context "when a path contains uppercase characters" do
    it "redirects to the lowercase route" do
      get path
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(path.downcase)
    end
  end
end

RSpec.describe "StoriesIndex", type: :request do
  describe "GET stories index" do
    it "renders page with article list" do
      article = create(:article, featured: true)

      get "/"
      expect(response.body).to include(CGI.escapeHTML(article.title))
    end

    it "renders registration page if site config is private" do
      SiteConfig.public = false

      get root_path
      expect(response.body).to include("Continue with")
    end

    it "renders proper description" do
      get "/"
      expect(response.body).to include(SiteConfig.community_description)
    end

    it "renders page with min read" do
      create(:article, featured: true)

      get "/"
      expect(response.body).to include("min read")
    end

    it "renders page with proper sidebar" do
      get "/"
      expect(response.body).to include("Podcasts")
    end

    it "renders left display_ads when published and approved" do
      org = create(:organization)
      ad = create(:display_ad, published: true, approved: true, organization: org)
      get "/"
      expect(response.body).to include(ad.processed_html)
    end

    it "renders right display_ads when published and approved" do
      org = create(:organization)
      ad = create(:display_ad, published: true, approved: true, placement_area: "sidebar_right", organization: org)
      get "/"
      expect(response.body).to include(ad.processed_html)
    end

    it "does not render left display_ads when not approved" do
      org = create(:organization)
      ad = create(:display_ad, published: true, approved: false, organization: org)
      get "/"
      expect(response.body).not_to include(ad.processed_html)
    end

    it "does not render right display_ads when not approved" do
      org = create(:organization)
      ad = create(:display_ad, published: true, approved: false, placement_area: "sidebar_right", organization: org)
      get "/"
      expect(response.body).not_to include(ad.processed_html)
    end

    it "has gold sponsors displayed" do
      org = create(:organization)
      sponsorship = create(:sponsorship, level: "gold", tagline: "Oh Yeah!!!", status: "live", organization: org)
      get "/"
      expect(response.body).to include(sponsorship.tagline)
    end

    it "does not display silver sponsors" do
      org = create(:organization)
      sponsorship = create(:sponsorship, level: "silver", tagline: "Oh Yeah!!!", status: "live", organization: org)
      get "/"
      expect(response.body).not_to include(sponsorship.tagline)
    end

    it "does not display non live gold sponsorships" do
      org = create(:organization)
      sponsorship = create(:sponsorship, level: "gold", tagline: "Oh Yeah!!!", status: "pending", organization: org)
      get "/"
      expect(response.body).not_to include(sponsorship.tagline)
    end

    it "shows listings" do
      user = create(:user)
      listing = create(:listing, user_id: user.id)
      get "/"
      expect(response.body).to include(CGI.escapeHTML(listing.title))
    end

    it "sets Fastly Surrogate-Key headers" do
      get "/"
      expect(response.status).to eq(200)

      expected_surrogate_key_headers = %w[main_app_home_page]
      expect(response.headers["Surrogate-Key"].split(", ")).to match_array(expected_surrogate_key_headers)
    end

    it "sets Nginx X-Accel-Expires headers" do
      get "/"
      expect(response.status).to eq(200)

      expect(response.headers["X-Accel-Expires"]).to eq("600")
    end

    it "shows default meta keywords" do
      SiteConfig.meta_keywords = { default: "cool developers, civil engineers" }
      get "/"
      expect(response.body).to include("<meta name=\"keywords\" content=\"cool developers, civil engineers\">")
    end

    it "shows only one cover if basic feed style" do
      create_list(:article, 3, featured: true, score: 20, main_image: "https://example.com/image.jpg")

      SiteConfig.feed_style = "basic"
      get "/"
      expect(response.body.scan(/(?=class="crayons-story__cover__image)/).count).to be 1
    end

    it "shows multiple cover images if rich feed style" do
      create_list(:article, 3, featured: true, score: 20, main_image: "https://example.com/image.jpg")

      SiteConfig.feed_style = "rich"
      get "/"
      expect(response.body.scan(/(?=class="crayons-story__cover__image)/).count).to be > 1
    end

    context "with campaign hero" do
      let!(:hero_html) do
        create(
          :html_variant,
          group: "campaign",
          name: "hero",
          html: "<em>#{Faker::Book.title}'s</em>",
          published: true,
          approved: true,
        )
      end

      it "displays hero html when it exists and is set in config" do
        SiteConfig.campaign_hero_html_variant_name = "hero"

        get root_path
        expect(response.body).to include(hero_html.html)
      end

      it "doesn't display when campaign_hero_html_variant_name is not set" do
        SiteConfig.campaign_hero_html_variant_name = ""

        get root_path
        expect(response.body).not_to include(hero_html.html)
      end

      it "doesn't display when hero html is not approved" do
        SiteConfig.campaign_hero_html_variant_name = "hero"
        hero_html.update_column(:approved, false)

        get root_path
        expect(response.body).not_to include(hero_html.html)
      end
    end

    context "with campaign_sidebar" do
      before do
        SiteConfig.campaign_featured_tags = "shecoded,theycoded"

        a_body = "---\ntitle: Super-sheep#{rand(1000)}\npublished: true\ntags: heyheyhey,shecoded\n---\n\nHello"
        create(:article, approved: true, body_markdown: a_body, score: 1)
        u_body = "---\ntitle: Unapproved-post#{rand(1000)}\npublished: true\ntags: heyheyhey,shecoded\n---\n\nHello"
        create(:article, approved: false, body_markdown: u_body, score: 1)
      end

      it "doesn't display posts with the campaign tags when sidebar is disabled" do
        SiteConfig.campaign_sidebar_enabled = false
        get "/"
        expect(response.body).not_to include(CGI.escapeHTML("Super-sheep"))
      end

      it "doesn't display low-score posts" do
        SiteConfig.campaign_sidebar_enabled = true
        SiteConfig.campaign_articles_require_approval = true
        get "/"
        expect(response.body).not_to include(CGI.escapeHTML("Unapproved-post"))
      end

      it "doesn't display unapproved posts" do
        SiteConfig.campaign_sidebar_enabled = true
        SiteConfig.campaign_sidebar_image = "https://example.com/image.png"
        SiteConfig.campaign_articles_require_approval = true
        Article.last.update_column(:score, -2)
        get "/"
        expect(response.body).not_to include(CGI.escapeHTML("Unapproved-post"))
      end

      it "displays unapproved post if approval is not required" do
        SiteConfig.campaign_sidebar_enabled = true
        SiteConfig.campaign_sidebar_image = "https://example.com/image.png"
        SiteConfig.campaign_articles_require_approval = false
        get "/"
        expect(response.body).to include(CGI.escapeHTML("Unapproved-post"))
      end

      it "displays only approved posts with the campaign tags" do
        SiteConfig.campaign_sidebar_enabled = false
        get "/"
        expect(response.body).not_to include(CGI.escapeHTML("Super-puper"))
      end

      it "displays sidebar url if campaign_url is set" do
        SiteConfig.campaign_sidebar_enabled = true
        SiteConfig.campaign_url = "https://campaign-lander.com"
        SiteConfig.campaign_sidebar_image = "https://example.com/image.png"
        get "/"
        expect(response.body).to include('<a href="https://campaign-lander.com"')
      end

      it "does not display sidebar url if image is not present is set" do
        SiteConfig.campaign_sidebar_enabled = true
        SiteConfig.campaign_url = "https://campaign-lander.com"
        get "/"
        expect(response.body).not_to include('<a href="https://campaign-lander.com"')
      end
    end
  end

  describe "GET query page" do
    it "renders page with proper header" do
      get "/search?q=hello"
      expect(response.body).to include("query-header-text")
    end
  end

  describe "GET podcast index" do
    include_examples "redirects to the lowercase route" do
      let(:path) { "/#{build(:podcast).slug.upcase}" }
    end

    it "renders page with proper header" do
      podcast = create(:podcast)
      create(:podcast_episode, podcast: podcast)
      get "/#{podcast.slug}"
      expect(response.body).to include(podcast.title)
    end
  end

  describe "GET tag index" do
    let(:user) { create(:user) }
    let(:tag) { create(:tag) }
    let(:org) { create(:organization) }

    def create_live_sponsor(org, tag)
      create(
        :sponsorship,
        level: :tag,
        blurb_html: "<p>Oh Yeah!!!</p>",
        status: "live",
        organization: org,
        sponsorable: tag,
        expires_at: 30.days.from_now,
      )
    end

    context "with caching headers" do
      before do
        get "/t/#{tag.name}"
      end

      it "renders page with proper header" do
        expect(response.body).to include(tag.name)
      end

      it "sets Fastly Cache-Control headers" do
        expect(response.status).to eq(200)

        expected_cache_control_headers = %w[public no-cache]
        expect(response.headers["Cache-Control"].split(", ")).to match_array(expected_cache_control_headers)
      end

      it "sets Fastly Surrogate-Control headers" do
        expect(response.status).to eq(200)

        expected_surrogate_control_headers = %w[max-age=600 stale-while-revalidate=30 stale-if-error=86400]
        expect(response.headers["Surrogate-Control"].split(", ")).to match_array(expected_surrogate_control_headers)
      end

      it "sets Fastly Surrogate-Key headers" do
        expect(response.status).to eq(200)

        expected_surrogate_key_headers = %W[articles-#{tag}]
        expect(response.headers["Surrogate-Key"].split(", ")).to match_array(expected_surrogate_key_headers)
      end

      it "sets Nginx X-Accel-Expires headers" do
        expect(response.status).to eq(200)

        expect(response.headers["X-Accel-Expires"]).to eq("600")
      end
    end

    it "renders page with top/week etc." do
      get "/t/#{tag.name}/top/week"
      expect(response.body).to include(tag.name)
      get "/t/#{tag.name}/top/month"
      expect(response.body).to include(tag.name)
      get "/t/#{tag.name}/top/year"
      expect(response.body).to include(tag.name)
      get "/t/#{tag.name}/top/infinity"
      expect(response.body).to include(tag.name)
    end

    it "renders tag after alias change" do
      tag2 = create(:tag, alias_for: tag.name)
      get "/t/#{tag2.name}"
      expect(response.body).to redirect_to "/t/#{tag.name}"
      expect(response).to have_http_status(:moved_permanently)
    end

    it "does not render sponsor if not live" do
      sponsorship = create(
        :sponsorship, level: :tag, tagline: "Oh Yeah!!!", status: "pending", organization: org, sponsorable: tag
      )

      get "/t/#{tag.name}"
      expect(response.body).not_to include("is sponsored by")
      expect(response.body).not_to include(sponsorship.tagline)
    end

    it "renders live sponsor" do
      sponsorship = create_live_sponsor(org, tag)
      get "/t/#{tag.name}"
      expect(response.body).to include("is sponsored by")
      expect(response.body).to include(sponsorship.blurb_html)
    end

    it "shows meta keywords" do
      SiteConfig.meta_keywords = { tag: "software engineering, ruby" }
      get "/t/#{tag.name}"
      expect(response.body).to include("<meta name=\"keywords\" content=\"software engineering, ruby, #{tag.name}\">")
    end

    context "with user signed in" do
      before do
        sign_in user
      end

      it "shows tags to signed-in users" do
        get "/t/#{tag.name}"
        expect(response.body).to include("crayons-tabs__item crayons-tabs__item--current")
      end

      it "renders properly even if site config is private" do
        SiteConfig.public = false
        get "/t/#{tag.name}"
        expect(response.body).to include("crayons-tabs__item crayons-tabs__item--current")
      end

      it "has mod-action-button" do
        get "/t/#{tag.name}"
        expect(response.body).to include('<a class="cta mod-action-button"')
      end

      it "does not render pagination" do
        get "/t/#{tag.name}"
        expect(response.body).not_to include('<span class="olderposts-pagenumber">')
      end

      it "does not render pagination even with many posts" do
        create_list(:article, 20, user: user, featured: true, tags: [tag.name], score: 20)
        get "/t/#{tag.name}"
        expect(response.body).not_to include('<span class="olderposts-pagenumber">')
      end
    end

    context "without user signed in" do
      let(:tag) { create(:tag) }

      it "shows sign-in notice to non-signed-in users" do
        get "/t/#{tag.name}"
        expect(response.body).not_to include("crayons-tabs__item crayons-tabs__item--current")
        expect(response.body).to include("for the ability sort posts by")
      end

      it "does not render pagination" do
        get "/t/#{tag.name}"
        expect(response.body).not_to include('<span class="olderposts-pagenumber">')
      end

      it "does not render pagination even with many posts" do
        create_list(:article, 20, user: user, featured: true, tags: [tag.name], score: 20)
        get "/t/#{tag.name}"
        expect(response.body).to include('<span class="olderposts-pagenumber">')
      end

      it "does not include sidebar for page tag" do
        create_list(:article, 20, user: user, featured: true, tags: [tag.name], score: 20)
        get "/t/#{tag.name}/page/2"
        expect(response.body).not_to include('<div id="sidebar-wrapper-right"')
      end

      it "renders proper page title for page 1" do
        create_list(:article, 20, user: user, featured: true, tags: [tag.name], score: 20)
        get "/t/#{tag.name}/page/1"
        expect(response.body).to include("<title>#{tag.name.capitalize} - ")
      end

      it "renders proper page title for page 2" do
        create_list(:article, 20, user: user, featured: true, tags: [tag.name], score: 20)
        get "/t/#{tag.name}/page/2"
        expect(response.body).to include("<title>#{tag.name.capitalize} Page 2 - ")
      end

      it "does not include current page link" do
        create_list(:article, 20, user: user, featured: true, tags: [tag.name], score: 20)
        get "/t/#{tag.name}/page/2"
        expect(response.body).to include('<span class="olderposts-pagenumber">2')
        expect(response.body).not_to include("<a href=\"/t/#{tag.name}/page/2")
        get "/t/#{tag.name}"
        expect(response.body).to include('<span class="olderposts-pagenumber">1')
        expect(response.body).not_to include("<a href=\"/t/#{tag.name}/page/1")
        expect(response.body).not_to include("<a href=\"/t/#{tag.name}/page/3")
      end

      it "renders proper canonical url for page 1" do
        get "/t/#{tag.name}"
        expect(response.body).to include("<link rel=\"canonical\" href=\"http://localhost:3000/t/#{tag.name}\" />")
      end

      it "renders proper canonical url for page 2" do
        get "/t/#{tag.name}/page/2"

        expected_tag = "<link rel=\"canonical\" href=\"http://localhost:3000/t/#{tag.name}/page/2\" />"
        expect(response.body).to include(expected_tag)
      end
    end
  end

  describe "GET user_path" do
    include_examples "redirects to the lowercase route" do
      let(:path) { "/#{build(:user).username.upcase}" }
    end
  end

  describe "GET organization_path" do
    include_examples "redirects to the lowercase route" do
      let(:path) { "/#{build(:organization).slug.upcase}" }
    end
  end
end
