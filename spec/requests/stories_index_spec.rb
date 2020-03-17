require "rails_helper"

RSpec.describe "StoriesIndex", type: :request do
  let!(:article) { create(:article, featured: true) }

  describe "GET stories index" do
    it "renders page with article list" do
      get "/"
      expect(response.body).to include(CGI.escapeHTML(article.title))
    end

    it "renders proper description" do
      get "/"
      expect(response.body).to include(SiteConfig.community_description)
    end

    it "renders page with min read" do
      get "/"
      expect(response.body).to include("min read")
    end

    it "renders page with proper sidebar" do
      get "/"
      expect(response.body).to include("<h4>Key links</h4>")
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
      listing = create(:classified_listing, user_id: user.id)
      get "/"
      expect(response.body).to include(CGI.escapeHTML(listing.title))
    end

    context "with campaign hero" do
      let_it_be_readonly(:hero_html) do
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
        create(:article, approved: true, body_markdown: a_body)
        u_body = "---\ntitle: Unapproved-post#{rand(1000)}\npublished: true\ntags: heyheyhey,shecoded\n---\n\nHello"
        create(:article, approved: false, body_markdown: u_body)
      end

      it "doesn't display posts with the campaign tags when sidebar is disabled" do
        SiteConfig.campaign_sidebar_enabled = false
        get "/"
        expect(response.body).not_to include(CGI.escapeHTML("Super-sheep"))
      end

      it "displays posts with the campaign tags when sidebar is enabled" do
        SiteConfig.campaign_sidebar_enabled = true
        get "/"
        expect(response.body).not_to include(CGI.escapeHTML("Unapproved-post"))
      end

      it "displays only approved posts with the campaign tags" do
        SiteConfig.campaign_sidebar_enabled = false
        get "/"
        expect(response.body).not_to include(CGI.escapeHTML("Super-puper"))
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
    it "renders page with proper header" do
      podcast = create(:podcast)
      create(:podcast_episode, podcast: podcast)
      get "/" + podcast.slug
      expect(response.body).to include(podcast.title)
    end
  end

  describe "GET tag index" do
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

    it "renders page with proper header" do
      get "/t/#{tag.name}"
      expect(response.body).to include(tag.name)
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
  end
end
