require "rails_helper"

RSpec.describe "Sitemaps", type: :request do
  describe "GET /sitemap-*" do
    it "renders xml file" do
      get "/sitemap-Mar-2011.xml"
      expect(response.media_type).to eq("application/xml")
    end

    it "renders not found if incorrect input" do
      expect { get "/sitemap-March-2011.xml" }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "renders not found if not valid date" do
      expect { get "/sitemap-Mak-2011.xml" }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "renders proper surrogate header for recent sitemap" do
      get "/sitemap-#{3.days.ago.strftime('%b-%Y')}.xml"
      expect(response.header["Surrogate-Control"]).to include("8640")
    end

    it "renders proper surrogate header for older sitemap" do
      get "/sitemap-#{35.days.ago.strftime('%b-%Y')}.xml"
      expect(response.header["Surrogate-Control"]).to include("259200")
    end

    it "sends a surrogate key (for Fastly's user)" do
      articles = create_list(:article, 4)
      included_articles = articles.first(3)
      included_articles.each { |a| a.update(published_at: "2020-03-07T00:27:30Z", score: 10) }

      get "/sitemap-Mar-2020.xml"

      article = included_articles.first

      expected_tag = "<loc>#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}#{article.path}</loc>"
      expect(response.body).to include(expected_tag)
      expect(response.body).to include("<lastmod>#{article.last_comment_at.strftime('%F')}</lastmod>")
      expect(response.body).not_to include(articles.last.path)
      expect(response.media_type).to eq("application/xml")
    end

    it "renders most recent posts if /sitemap-posts", :aggregate_failures do
      create_list(:article, 8)
      get "/sitemap-posts.xml"
      expect(response.body).to include(Article.order("published_at DESC").first.path)
      expect(response.body).not_to include(Article.order("published_at DESC").last.path)
    end

    it "renders second page if /sitemap-posts-1", :aggregate_failures do
      create_list(:article, 8)
      get "/sitemap-posts-1.xml"
      expect(response.body).not_to include(Article.order("published_at DESC").first.path)
      expect(response.body).to include(Article.order("published_at DESC").last.path)
    end

    it "renders first page if /sitemap-posts-randomn0tnumber", :aggregate_failures do
      create_list(:article, 8)
      get "/sitemap-posts-randomn0tnumber.xml"
      expect(response.body).to include(Article.order("published_at DESC").first.path)
      expect(response.body).not_to include(Article.order("published_at DESC").last.path)
    end

    it "renders empty if /sitemap-posts-2", :aggregate_failures do
      # no posts this far down.
      create_list(:article, 8)
      get "/sitemap-posts-2.xml"
      expect(response.body).not_to include(Article.order("published_at DESC").first.path)
      expect(response.body).not_to include(Article.order("published_at DESC").last.path)
    end

    it "renders 'recent' version of surrogate control" do
      get "/sitemap-posts-2.xml"
      expect(response.header["Surrogate-Control"]).to include("8640")
    end
  end
end
