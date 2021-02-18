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
    let(:user) { create(:user) }

    it "renders page with article list and proper attributes", :aggregate_failures do
      article = create(:article, featured: true)
      navigation_link = create(:navigation_link)

      get "/"
      expect(response.body).to include(CGI.escapeHTML(article.title))
      renders_ga_tracking_data
      renders_proper_description
      renders_min_read_time
      renders_proper_sidebar(navigation_link)
    end

    def renders_proper_description
      expect(response.body).to include(SiteConfig.community_description)
    end

    def renders_min_read_time
      expect(response.body).to include("min read")
    end

    def renders_proper_sidebar(navigation_link)
      expect(response.body).to include(CGI.escapeHTML(navigation_link.name))
    end

    def renders_ga_tracking_data
      expect(response.body).to include("data-ga-tracking=\"#{SiteConfig.ga_tracking_id}\"")
    end

    it "renders registration page if site config is private" do
      allow(SiteConfig).to receive(:public).and_return(false)

      get root_path
      expect(response.body).to include("Continue with")
    end

    it "renders all display_ads when published and approved" do
      org = create(:organization)
      ad = create(:display_ad, published: true, approved: true, organization: org)
      right_ad = create(:display_ad, published: true, approved: true, placement_area: "sidebar_right",
                                     organization: org)

      get "/"
      expect(response.body).to include(ad.processed_html)
      expect(response.body).to include(right_ad.processed_html)
    end

    it "does not render display_ads when not approved" do
      org = create(:organization)
      ad = create(:display_ad, published: true, approved: false, organization: org)
      right_ad = create(:display_ad, published: true, approved: false, placement_area: "sidebar_right",
                                     organization: org)

      get "/"
      expect(response.body).not_to include(ad.processed_html)
      expect(response.body).not_to include(right_ad.processed_html)
    end

    it "displays correct sponsors", :aggregate_failures do
      org = create(:organization)
      gold_sponsorship = create(:sponsorship, level: "gold", tagline: "GOLD!!!", status: "live", organization: org)
      silver_sponsorship = create(:sponsorship, level: "silver", tagline: "SILVER!!!", status: "live",
                                                organization: org)
      non_live_gold_sponsorship = create(:sponsorship, level: "gold", tagline: "NOT LIVE GOLD!!!", status: "pending",
                                                       organization: org)
      get "/"

      displays_gold_sponsors(gold_sponsorship)
      does_not_display_silver_sponsors(silver_sponsorship)
      does_not_display_non_live_gold_sponsors(non_live_gold_sponsorship)
    end

    def displays_gold_sponsors(sponsorship)
      expect(response.body).to include(sponsorship.tagline)
    end

    def does_not_display_silver_sponsors(sponsorship)
      expect(response.body).not_to include(sponsorship.tagline)
    end

    def does_not_display_non_live_gold_sponsors(sponsorship)
      expect(response.body).not_to include(sponsorship.tagline)
    end

    it "shows listings" do
      user = create(:user)
      listing = create(:listing, user_id: user.id)
      get "/"
      expect(response.body).to include(CGI.escapeHTML(listing.title))
    end

    it "does not set cache-related headers if private" do
      allow(SiteConfig).to receive(:public).and_return(false)
      get "/"
      expect(response.status).to eq(200)

      expect(response.headers["X-Accel-Expires"]).to eq(nil)
      expect(response.headers["Cache-Control"]).not_to eq("public, no-cache")
      expect(response.headers["Surrogate-Key"]).to eq(nil)
    end

    it "sets correct cache headers", :aggregate_failures do
      get "/"

      expect(response.status).to eq(200)
      sets_fastly_headers
      sets_nginx_headers
    end

    def sets_fastly_headers
      expected_surrogate_key_headers = %w[main_app_home_page]
      expect(response.headers["Surrogate-Key"].split(", ")).to match_array(expected_surrogate_key_headers)
    end

    def sets_nginx_headers
      expect(response.headers["X-Accel-Expires"]).to eq("600")
    end

    it "shows default meta keywords if set" do
      allow(SiteConfig).to receive(:meta_keywords).and_return({ default: "cool developers, civil engineers" })
      get "/"
      expect(response.body).to include("<meta name=\"keywords\" content=\"cool developers, civil engineers\">")
    end

    it "does not show default meta keywords if not set" do
      allow(SiteConfig).to receive(:meta_keywords).and_return({ default: "" })
      get "/"
      expect(response.body).not_to include(
        "<meta name=\"keywords\" content=\"cool developers, civil engineers\">",
      )
    end

    it "shows only one cover if basic feed style" do
      create_list(:article, 3, featured: true, score: 20, main_image: "https://example.com/image.jpg")

      allow(SiteConfig).to receive(:feed_style).and_return("basic")
      get "/"
      expect(response.body.scan(/(?=class="crayons-story__cover__image)/).count).to be 1
    end

    it "shows multiple cover images if rich feed style" do
      create_list(:article, 3, featured: true, score: 20, main_image: "https://example.com/image.jpg")

      allow(SiteConfig).to receive(:feed_style).and_return("rich")
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
        allow(SiteConfig).to receive(:campaign_hero_html_variant_name).and_return("hero")

        get root_path
        expect(response.body).to include(hero_html.html)
      end

      it "doesn't display when campaign_hero_html_variant_name is not set" do
        allow(SiteConfig).to receive(:campaign_hero_html_variant_name).and_return("")

        get root_path
        expect(response.body).not_to include(hero_html.html)
      end

      it "doesn't display when hero html is not approved" do
        allow(SiteConfig).to receive(:campaign_hero_html_variant_name).and_return("hero")
        hero_html.update_column(:approved, false)

        get root_path
        expect(response.body).not_to include(hero_html.html)
      end
    end

    context "with campaign_sidebar" do
      before do
        allow(SiteConfig).to receive(:campaign_featured_tags).and_return("shecoded,theycoded")
        allow(SiteConfig).to receive(:home_feed_minimum_score).and_return(7)

        a_body = "---\ntitle: Super-sheep#{rand(1000)}\npublished: true\ntags: heyheyhey,shecoded\n---\n\nHello"
        create(:article, approved: true, body_markdown: a_body, score: 1)
        u_body = "---\ntitle: Unapproved-post#{rand(1000)}\npublished: true\ntags: heyheyhey,shecoded\n---\n\nHello"
        create(:article, approved: false, body_markdown: u_body, score: 1)
      end

      it "doesn't display posts with the campaign tags when sidebar is disabled" do
        allow(SiteConfig).to receive(:campaign_sidebar_enabled).and_return(false)
        get "/"
        expect(response.body).not_to include(CGI.escapeHTML("Super-sheep"))
      end

      it "doesn't display low-score posts" do
        allow(SiteConfig).to receive(:campaign_sidebar_enabled).and_return(true)
        allow(SiteConfig).to receive(:campaign_articles_require_approval).and_return(true)
        get "/"
        expect(response.body).not_to include(CGI.escapeHTML("Unapproved-post"))
      end

      it "doesn't display unapproved posts" do
        allow(SiteConfig).to receive(:campaign_sidebar_enabled).and_return(true)
        allow(SiteConfig).to receive(:campaign_sidebar_image).and_return("https://example.com/image.png")
        allow(SiteConfig).to receive(:campaign_articles_require_approval).and_return(true)
        Article.last.update_column(:score, -2)
        get "/"
        expect(response.body).not_to include(CGI.escapeHTML("Unapproved-post"))
      end

      it "displays unapproved post if approval is not required" do
        allow(SiteConfig).to receive(:campaign_sidebar_enabled).and_return(true)
        allow(SiteConfig).to receive(:campaign_sidebar_image).and_return("https://example.com/image.png")
        allow(SiteConfig).to receive(:campaign_articles_require_approval).and_return(false)
        get "/"
        expect(response.body).to include(CGI.escapeHTML("Unapproved-post"))
      end

      it "displays only approved posts with the campaign tags" do
        allow(SiteConfig).to receive(:campaign_sidebar_enabled).and_return(false)
        get "/"
        expect(response.body).not_to include(CGI.escapeHTML("Super-puper"))
      end

      it "displays sidebar url if campaign_url is set" do
        allow(SiteConfig).to receive(:campaign_sidebar_enabled).and_return(true)
        allow(SiteConfig).to receive(:campaign_url).and_return("https://campaign-lander.com")
        allow(SiteConfig).to receive(:campaign_sidebar_image).and_return("https://example.com/image.png")
        get "/"
        expect(response.body).to include('<a href="https://campaign-lander.com"')
      end

      it "does not display sidebar url if image is not present is set" do
        allow(SiteConfig).to receive(:campaign_sidebar_enabled).and_return(true)
        allow(SiteConfig).to receive(:campaign_url).and_return("https://campaign-lander.com")
        get "/"
        expect(response.body).not_to include('<a href="https://campaign-lander.com"')
      end
    end
  end

  describe "GET query page" do
    it "renders page with proper header" do
      get "/search?q=hello"
      expect(response.body).to include("=> Search Results")
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
      it "renders page and sets proper headers", :aggregate_failures do
        get "/t/#{tag.name}"

        renders_page
        sets_fastly_headers
        sets_nginx_headers
      end

      def renders_page
        expect(response.status).to eq(200)
        expect(response.body).to include(tag.name)
      end

      def sets_fastly_headers
        expected_cache_control_headers = %w[public no-cache]
        expect(response.headers["Cache-Control"].split(", ")).to match_array(expected_cache_control_headers)

        expected_surrogate_control_headers = %w[max-age=600 stale-while-revalidate=30 stale-if-error=86400]
        expect(response.headers["Surrogate-Control"].split(", ")).to match_array(expected_surrogate_control_headers)

        expected_surrogate_key_headers = %W[articles-#{tag}]
        expect(response.headers["Surrogate-Key"].split(", ")).to match_array(expected_surrogate_key_headers)
      end

      def sets_nginx_headers
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

    it "shows meta keywords if set" do
      allow(SiteConfig).to receive(:meta_keywords).and_return({ tag: "software engineering, ruby" })
      get "/t/#{tag.name}"
      expect(response.body).to include("<meta name=\"keywords\" content=\"software engineering, ruby, #{tag.name}\">")
    end

    it "does not show meta keywords if not set" do
      allow(SiteConfig).to receive(:meta_keywords).and_return({ tag: "" })
      get "/t/#{tag.name}"
      expect(response.body).not_to include(
        "<meta name=\"keywords\" content=\"software engineering, ruby, #{tag.name}\">",
      )
    end

    context "with user signed in" do
      before do
        sign_in user
      end

      it "shows tags and renders properly", :aggregate_failures do
        get "/t/#{tag.name}"
        expect(response.body).to include("crayons-tabs__item crayons-tabs__item--current")
        has_mod_action_button
        does_not_paginate
        sets_remember_token
      end

      def has_mod_action_button
        expect(response.body).to include('class="crayons-btn crayons-btn--outlined mod-action-button fs-s"')
      end

      def does_not_paginate
        expect(response.body).not_to include('<span class="olderposts-pagenumber">')
      end

      def sets_remember_token
        expect(response.cookies["remember_user_token"]).not_to be nil
      end

      it "renders properly even if site config is private" do
        allow(SiteConfig).to receive(:public).and_return(false)
        get "/t/#{tag.name}"
        expect(response.body).to include("crayons-tabs__item crayons-tabs__item--current")
      end

      it "does not render pagination even with many posts" do
        create_list(:article, 20, user: user, featured: true, tags: [tag.name], score: 20)
        get "/t/#{tag.name}"
        expect(response.body).not_to include('<span class="olderposts-pagenumber">')
      end
    end

    context "without user signed in" do
      let(:tag) { create(:tag) }

      it "renders tag index properly with many posts", :aggregate_failures do
        stub_const("StoriesController::SIGNED_OUT_RECORD_COUNT", 10)
        create_list(:article, 20, user: user, featured: true, tags: [tag.name], score: 20)
        get "/t/#{tag.name}"

        shows_sign_in_notice
        does_not_include_current_page_link(tag)
        does_not_set_remember_token
        renders_pagination
      end

      def shows_sign_in_notice
        expect(response.body).not_to include("crayons-tabs__item crayons-tabs__item--current")
        expect(response.body).to include("for the ability sort posts by")
      end

      def does_not_include_current_page_link(tag)
        expect(response.body).to include('<span class="olderposts-pagenumber">1')
        expect(response.body).not_to include("<a href=\"/t/#{tag.name}/page/1")
        expect(response.body).not_to include("<a href=\"/t/#{tag.name}/page/3")
      end

      def does_not_set_remember_token
        expect(response.cookies["remember_user_token"]).to be nil
      end

      def renders_pagination
        expect(response.body).to include('<span class="olderposts-pagenumber">')
      end

      it "renders tag index without pagination when not needed" do
        get "/t/#{tag.name}"

        expect(response.body).not_to include('<span class="olderposts-pagenumber">')
      end

      it "does not include sidebar for page tag" do
        create_list(:article, 20, user: user, featured: true, tags: [tag.name], score: 20)
        get "/t/#{tag.name}/page/2"
        expect(response.body).not_to include('<div id="sidebar-wrapper-right"')
      end

      it "renders proper page 1", :aggregate_failures do
        create_list(:article, 20, user: user, featured: true, tags: [tag.name], score: 20)
        get "/t/#{tag.name}/page/1"

        renders_title(tag)
        renders_canonical_url(tag)
      end

      def renders_title(tag)
        expect(response.body).to include("<title>#{tag.name.capitalize} - ")
      end

      def renders_canonical_url(tag)
        expect(response.body).to include("<link rel=\"canonical\" href=\"http://localhost:3000/t/#{tag.name}\" />")
      end

      it "renders proper page 2", :aggregate_failures do
        create_list(:article, 20, user: user, featured: true, tags: [tag.name], score: 20)
        get "/t/#{tag.name}/page/2"

        renders_page_2_title(tag)
        renders_page_2_canonical_url(tag)
      end

      def renders_page_2_title(tag)
        expect(response.body).to include("<title>#{tag.name.capitalize} Page 2 - ")
      end

      def renders_page_2_canonical_url(tag)
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
