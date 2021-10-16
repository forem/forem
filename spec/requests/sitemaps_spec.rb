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

    context "with index in param" do
      it "renders basic index", :aggregate_failures do
        get "/sitemap-index.xml"
        expect(response.body).to include("<sitemapindex xmlns=")
        expect(response.body).to include("sitemap-posts.xml")
        expect(response.body).to include("sitemap-users.xml")
        expect(response.body).to include("sitemap-tags.xml")
      end

      it "renders multiple posts pages if enough posts", :aggregate_failures do
        create_list(:article, 13, score: 10)
        get "/sitemap-index.xml"
        expect(response.body).not_to include("sitemap-posts.xml")
        expect(response.body).to include("sitemap-posts-0.xml")
        expect(response.body).to include("sitemap-posts-2.xml")
        expect(response.body).not_to include("sitemap-posts-3.xml")
      end
    end

    context "with posts in param" do
      before do
        create_list(:article, 8, score: 10)
      end

      it "renders most recent posts if /sitemap-posts", :aggregate_failures do
        get "/sitemap-posts.xml"
        expect(response.body).to include(Article.order("published_at DESC").first.path)
        expect(response.body).not_to include(Article.order("published_at DESC").last.path)
      end

      it "renders second page if /sitemap-posts-1", :aggregate_failures do
        get "/sitemap-posts-1.xml"
        expect(response.body).not_to include(Article.order("published_at DESC").first.path)
        expect(response.body).to include(Article.order("published_at DESC").last.path)
      end

      it "renders first page if /sitemap-posts-randomn0tnumber", :aggregate_failures do
        get "/sitemap-posts-randomn0tnumber.xml"
        expect(response.body).to include(Article.order("published_at DESC").first.path)
        expect(response.body).not_to include(Article.order("published_at DESC").last.path)
      end

      it "renders empty if /sitemap-posts-2", :aggregate_failures do
        # no posts this far down.
        get "/sitemap-posts-2.xml"
        expect(response.body).not_to include(Article.order("published_at DESC").first.path)
        expect(response.body).not_to include(Article.order("published_at DESC").last.path)
      end

      it "renders 'recent' version of surrogate control" do
        get "/sitemap-posts-2.xml"
        expect(response.header["Surrogate-Control"]).to include("8640")
      end
    end

    context "with tags in param" do
      before do
        create_list(:tag, 8)
        Tag.all.each do |tag|
          tag.update_column(:hotness_score, rand(100_000))
        end
      end

      it "renders hottest tags if /sitemap-tags", :aggregate_failures do
        get "/sitemap-tags.xml"
        expect(response.body).to include(Tag.order("hotness_score DESC").first.name)
        expect(response.body).not_to include(Tag.order("hotness_score DESC").last.name)
      end

      it "renders second page if /sitemap-tags-1", :aggregate_failures do
        get "/sitemap-tags-1.xml"
        expect(response.body).not_to include(Tag.order("hotness_score DESC").first.name)
        expect(response.body).to include(Tag.order("hotness_score DESC").last.name)
      end

      it "renders first page if /sitemap-tags-randomn0tnumber", :aggregate_failures do
        get "/sitemap-tags-randomn0tnumber.xml"
        expect(response.body).to include(Tag.order("hotness_score DESC").first.name)
        expect(response.body).not_to include(Tag.order("hotness_score DESC").last.name)
      end

      it "renders empty if /sitemap-tags-2", :aggregate_failures do
        # no posts this far down.
        get "/sitemap-tags-2.xml"
        expect(response.body).not_to include(Tag.order("hotness_score DESC").first.name)
        expect(response.body).not_to include(Tag.order("hotness_score DESC").last.name)
      end
    end

    context "with users in param" do
      before do
        create_list(:user, 8)
        User.all.each do |user|
          user.update_column(:comments_count, rand(100_000))
        end
      end

      it "renders hottest tags if /sitemap-users", :aggregate_failures do
        get "/sitemap-users.xml"
        expect(response.body).to include(User.order("comments_count DESC").first.username)
        expect(response.body).not_to include(User.order("comments_count DESC").last.username)
      end

      it "renders second page if /sitemap-users-1", :aggregate_failures do
        get "/sitemap-users-1.xml"
        expect(response.body).not_to include(User.order("comments_count DESC").first.username)
        expect(response.body).to include(User.order("comments_count DESC").last.username)
      end

      it "renders first page if /sitemap-users-randomn0tnumber", :aggregate_failures do
        get "/sitemap-users-randomn0tnumber.xml"
        expect(response.body).to include(User.order("comments_count DESC").first.username)
        expect(response.body).not_to include(User.order("comments_count DESC").last.username)
      end

      it "renders empty if /sitemap-users-2", :aggregate_failures do
        # no posts this far down.
        get "/sitemap-users-2.xml"
        expect(response.body).not_to include(User.order("comments_count DESC").first.username)
        expect(response.body).not_to include(User.order("comments_count DESC").last.username)
      end
    end
  end
end
