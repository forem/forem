require "rails_helper"

RSpec.describe "Trends", type: :request do
  describe "GET /trending" do
    it "renders the trends list" do
      allow(Images::Optimizer).to receive(:call).and_call_original
      allow(Images::Optimizer).to receive(:call)
        .with("https://example.com/ruby34.png", hash_including(width: 750))
        .and_return("https://optimized.example.com/ruby34_750.png")

      trend1 = create(:trend, name: "Ruby 3.4 release", score: 10, cover_image: "https://example.com/ruby34.png")
      trend2 = create(:trend, name: "AI Agent Revolution", score: 5)

      get trending_index_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Emergent Trends", "Ruby 3.4 release", "AI Agent Revolution")
      expect(response.body).to include("https://optimized.example.com/ruby34_750.png")
      expect(response.body).to include("What the community is talking about right now.")

      # Assert surrogate keys
      expect(response.headers["Surrogate-Key"]).to include("trends")
      expect(response.headers["Surrogate-Key"]).to include(trend1.record_key)
      expect(response.headers["Surrogate-Key"]).to include(trend2.record_key)
    end
  end

  describe "GET /trending/:slug" do
    it "renders the trend details and list of articles" do
      allow(Images::Optimizer).to receive(:call).and_call_original
      allow(Images::Optimizer).to receive(:call)
        .with("https://example.com/ruby34_large.png", hash_including(width: 500))
        .and_return("https://optimized.example.com/ruby34_500.png")
      allow(Images::Optimizer).to receive(:call)
        .with("https://example.com/ruby34_large.png", hash_including(width: 1200))
        .and_return("https://optimized.example.com/ruby34_1200.png")

      trend = create(:trend, name: "Ruby 3.4 release", description: "Awesome discussions about Ruby 3.4 features", cover_image: "https://example.com/ruby34_large.png")
      article1 = create(:article, published: true, title: "Ruby 3.4 features deep dive")
      article2 = create(:article, published: true, title: "Why I love Ruby 3.4")

      create(:trend_membership, trend: trend, article: article1, distance: 0.05)
      create(:trend_membership, trend: trend, article: article2, distance: 0.12)

      get trending_path(trend.slug)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ruby 3.4 release", "Awesome discussions about Ruby 3.4 features")
      expect(response.body).to include("Ruby 3.4 features deep dive", "Why I love Ruby 3.4")
      expect(response.body).to include("About this trend")
      expect(response.body).to include("This trend groups posts from the last 7 days that discuss similar concepts, technologies, or ideas.")
      
      # Assert cover image and OG/Twitter tags
      expect(response.body).to include("https://optimized.example.com/ruby34_500.png")
      expect(response.body).to include('property="og:image" content="https://optimized.example.com/ruby34_1200.png"')
      expect(response.body).to include('name="twitter:image:src" content="https://optimized.example.com/ruby34_1200.png"')

      # Assert surrogate keys
      expect(response.headers["Surrogate-Key"]).to include(trend.record_key)
      expect(response.headers["Surrogate-Key"]).to include(article1.record_key)
      expect(response.headers["Surrogate-Key"]).to include(article2.record_key)
    end
  end

  describe "Redirects from legacy /trends paths" do
    it "redirects from /trends to /trending" do
      get "/trends"
      expect(response).to redirect_to("/trending")
    end

    it "redirects from /trends/:slug to /trending/:slug" do
      get "/trends/some-slug"
      expect(response).to redirect_to("/trending/some-slug")
    end

    it "redirects while preserving the locale prefix if present" do
      get "/locale/fr/trends"
      expect(response).to redirect_to("/locale/fr/trending")

      get "/locale/pt/trends/some-slug"
      expect(response).to redirect_to("/locale/pt/trending/some-slug")
    end
  end
end
