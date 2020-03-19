require "rails_helper"

RSpec.describe "Sitemaps", type: :request do
  describe "GET /sitemap-*" do
    it "renders xml file" do
      get "/sitemap-Mar-2011.xml"
      expect(response.content_type).to eq("application/xml")
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
      create_list(:article, 4)
      Article.limit(3).update_all(published_at: 3.months.ago, score: 10)
      get "/sitemap-#{3.months.ago.strftime('%b-%Y')}.xml"
      article = Article.first
      expect(response.body).to include("<loc>#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}#{article.path}</loc>")
      expect(response.body).to include("<lastmod>#{article.last_comment_at.strftime('%F')}</lastmod>")
      expect(response.body).not_to include(Article.last.path)
      expect(response.content_type).to eq("application/xml")
    end
  end
end
