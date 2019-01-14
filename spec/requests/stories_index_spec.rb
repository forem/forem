require "rails_helper"

RSpec.describe "StoriesIndex", type: :request do
  describe "GET stories index" do
    it "renders page with proper sidebar" do
      get "/"
      expect(response.body).to include("key links")
    end
    xit "renders page with min read" do
      create_list(:article, 10, featured: true)
      get "/"
      expect(response.body).to include("min read")
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
      get "/" + podcast.slug
      expect(response.body).to include(podcast.title)
    end
  end

  describe "GET tag index" do
    it "renders page with proper header" do
      tag = create(:tag)
      get "/t/#{tag.name}"
      expect(response.body).to include(tag.name)
    end

    it "renders page with top/week etc." do
      tag = create(:tag)
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
      tag = create(:tag)
      tag2 = create(:tag, alias_for: tag.name)
      get "/t/#{tag2.name}"
      expect(response.body).to redirect_to "/t/#{tag.name}"
    end
  end
end
