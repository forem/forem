require "rails_helper"

RSpec.describe "StoriesIndex", type: :request do
  describe "GET stories index" do
    it "renders page with proper sidebar" do
      get "/"
      expect(response.body).to include("key links")
    end

    it "renders page with min read" do
      create(:article, featured: true)
      get "/"
      expect(response.body).to include("min read")
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
      org = create(:organization)
      sponsorship = create(:sponsorship, level: :tag, tagline: "Oh Yeah!!!", status: "pending", organization: org, sponsorable: tag)

      get "/t/#{tag.name}"
      expect(response.body).not_to include("is sponsored by")
      expect(response.body).not_to include(sponsorship.tagline)
    end

    it "renders live sponsor" do
      org = create(:organization)
      sponsorship = create(:sponsorship, level: :tag, tagline: "Oh Yeah!!!", status: "live", organization: org, sponsorable: tag)

      get "/t/#{tag.name}"
      expect(response.body).to include("is sponsored by")
      expect(response.body).to include(sponsorship.tagline)
    end
  end
end
