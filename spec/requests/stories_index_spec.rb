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
      expect(response.body).to include(Settings::Community.community_description)
    end

    def renders_min_read_time
      expect(response.body).to include("min read")
    end

    def renders_proper_sidebar(navigation_link)
      expect(response.body).to include(CGI.escapeHTML(navigation_link.name))
    end

    def renders_ga_tracking_data
      expect(response.body).to include("data-ga-tracking=\"#{Settings::General.ga_tracking_id}\"")
    end

    it "renders registration page if the Forem instance is private" do
      allow(Settings::UserExperience).to receive(:public).and_return(false)

      get root_path
      expect(response.body).to include("Continue with")
    end

    it "renders a landing page if one is active and if the site config is set to private" do
      allow(Settings::UserExperience).to receive(:public).and_return(false)
      create(:page, title: "This is a landing page!", landing_page: true)

      get root_path
      expect(response.body).to include("This is a landing page!")
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
      allow(Settings::UserExperience).to receive(:public).and_return(false)
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
      allow(Settings::General).to receive(:meta_keywords).and_return({ default: "cool developers, civil engineers" })
      get "/"
      expect(response.body).to include("<meta name=\"keywords\" content=\"cool developers, civil engineers\">")
    end

    it "does not show default meta keywords if not set" do
      allow(Settings::General).to receive(:meta_keywords).and_return({ default: "" })
      get "/"
      expect(response.body).not_to include(
        "<meta name=\"keywords\" content=\"cool developers, civil engineers\">",
      )
    end

    it "shows only one cover if basic feed style" do
      create_list(:article, 3, featured: true, score: 20, main_image: "https://example.com/image.jpg")

      allow(Settings::UserExperience).to receive(:feed_style).and_return("basic")
      get "/"
      expect(response.body.scan(/(?=class="crayons-story__cover crayons-story__cover__image)/).count).to be 1
    end

    it "shows multiple cover images if rich feed style" do
      create_list(:article, 3, featured: true, score: 20, main_image: "https://example.com/image.jpg")

      allow(Settings::UserExperience).to receive(:feed_style).and_return("rich")
      get "/"
      expect(response.body.scan(/(?=class="crayons-story__cover crayons-story__cover__image)/).count).to be > 1
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
        allow(Settings::Campaign).to receive(:hero_html_variant_name).and_return("hero")

        get root_path
        expect(response.body).to include(hero_html.html)
      end

      it "doesn't display when hero_html_variant_name is not set" do
        allow(Settings::Campaign).to receive(:hero_html_variant_name).and_return("")

        get root_path
        expect(response.body).not_to include(hero_html.html)
      end

      it "doesn't display when hero html is not approved" do
        allow(Settings::Campaign).to receive(:hero_html_variant_name).and_return("hero")
        hero_html.update_column(:approved, false)

        get root_path
        expect(response.body).not_to include(hero_html.html)
      end
    end

    context "with campaign_sidebar" do
      before do
        allow(Settings::Campaign).to receive(:featured_tags).and_return("mytag,yourtag")
        allow(Settings::UserExperience).to receive(:home_feed_minimum_score).and_return(7)

        a_body = "---\ntitle: Super-sheep#{rand(1000)}\npublished: true\ntags: heyheyhey,mytag\n---\n\nHello"
        create(:article, approved: true, body_markdown: a_body, score: 1)
        u_body = "---\ntitle: Unapproved-post#{rand(1000)}\npublished: true\ntags: heyheyhey,mytag\n---\n\nHello"
        create(:article, approved: false, body_markdown: u_body, score: 1)
      end

      it "doesn't display posts with the campaign tags when sidebar is disabled" do
        allow(Settings::Campaign).to receive(:sidebar_enabled).and_return(false)
        get "/"
        expect(response.body).not_to include(CGI.escapeHTML("Super-sheep"))
      end

      it "doesn't display low-score posts" do
        allow(Settings::Campaign).to receive(:sidebar_enabled).and_return(true)
        allow(Settings::Campaign).to receive(:articles_require_approval).and_return(true)
        get "/"
        expect(response.body).not_to include(CGI.escapeHTML("Unapproved-post"))
      end

      it "doesn't display unapproved posts" do
        allow(Settings::Campaign).to receive(:sidebar_enabled).and_return(true)
        allow(Settings::Campaign).to receive(:sidebar_image).and_return("https://example.com/image.png")
        allow(Settings::Campaign).to receive(:articles_require_approval).and_return(true)
        Article.last.update_column(:score, -2)
        get "/"
        expect(response.body).not_to include(CGI.escapeHTML("Unapproved-post"))
      end

      it "displays unapproved post if approval is not required" do
        allow(Settings::Campaign).to receive(:sidebar_enabled).and_return(true)
        allow(Settings::Campaign).to receive(:sidebar_image).and_return("https://example.com/image.png")
        allow(Settings::Campaign).to receive(:articles_require_approval).and_return(false)
        get "/"
        expect(response.body).to include(CGI.escapeHTML("Unapproved-post"))
      end

      it "displays only approved posts with the campaign tags" do
        allow(Settings::Campaign).to receive(:sidebar_enabled).and_return(false)
        get "/"
        expect(response.body).not_to include(CGI.escapeHTML("Super-puper"))
      end

      it "displays sidebar url if url is set" do
        allow(Settings::Campaign).to receive(:sidebar_enabled).and_return(true)
        allow(Settings::Campaign).to receive(:url).and_return("https://campaign-lander.com")
        allow(Settings::Campaign).to receive(:sidebar_image).and_return("https://example.com/image.png")
        get "/"
        expect(response.body).to include('<a href="https://campaign-lander.com"')
      end

      it "does not display sidebar url if image is not present is set" do
        allow(Settings::Campaign).to receive(:sidebar_enabled).and_return(true)
        allow(Settings::Campaign).to receive(:url).and_return("https://campaign-lander.com")
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
