require "rails_helper"

RSpec.describe "Sitemaps" do
  let(:user) { create(:user) }

  def create(name, *traits, **options)
    return super(:user, :without_profile, *traits, profile_image: nil, **options) if name == :user

    if name == :article
      options[:user] ||= user
      options[:with_tags] = false unless options.key?(:with_tags)
      options[:with_main_image] = false unless options.key?(:with_main_image)
    end
    super
  end

  def create_list(name, amount, *traits, **options)
    Array.new(amount) { create(name, *traits, **options) }
  end

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
      included_articles.each { |a| a.update_columns(published_at: "2020-03-07T00:27:30Z", score: 10) }

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
        stub_const("SitemapsController::RESULTS_LIMIT", 1)
        create_list(:article, 2, score: 10)
        get "/sitemap-index.xml"
        expect(response.body).not_to include("sitemap-posts.xml")
        expect(response.body).to include("sitemap-posts-0.xml")
        expect(response.body).to include("sitemap-posts-2.xml")
        expect(response.body).not_to include("sitemap-posts-3.xml")
      end
    end

    context "with posts in param" do
      it "paginates posts sitemaps and sets recent surrogate control", :aggregate_failures do
        stub_const("SitemapsController::RESULTS_LIMIT", 1)
        first_post = create(:article, :past, score: 10, past_published_at: 1.minute.ago)
        second_post = create(:article, :past, score: 10, past_published_at: 2.minutes.ago)

        get "/sitemap-posts.xml"
        expect(response.body).to include(first_post.path)
        expect(response.body).not_to include(second_post.path)

        get "/sitemap-posts-1.xml"
        expect(response.body).not_to include(first_post.path)
        expect(response.body).to include(second_post.path)

        get "/sitemap-posts-randomn0tnumber.xml"
        expect(response.body).to include(first_post.path)
        expect(response.body).not_to include(second_post.path)

        get "/sitemap-posts-2.xml"
        expect(response.body).not_to include(first_post.path, second_post.path)
        expect(response.header["Surrogate-Control"]).to include("8640")
      end

      it "renders not found if over max offset" do
        expect { get "/sitemap-posts-251.xml" }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with tags in param" do
      it "paginates hottest tags across sitemap pages", :aggregate_failures do
        stub_const("SitemapsController::RESULTS_LIMIT", 1)
        top_tag = create(:tag)
        second_tag = create(:tag)
        top_tag.update_column(:hotness_score, 200)
        second_tag.update_column(:hotness_score, 100)

        get "/sitemap-tags.xml"
        expect(response.body).to include(top_tag.name)
        expect(response.body).not_to include(second_tag.name)

        get "/sitemap-tags-1.xml"
        expect(response.body).not_to include(top_tag.name)
        expect(response.body).to include(second_tag.name)

        get "/sitemap-tags-randomn0tnumber.xml"
        expect(response.body).to include(top_tag.name)
        expect(response.body).not_to include(second_tag.name)

        get "/sitemap-tags-2.xml"
        expect(response.body).not_to include(top_tag.name, second_tag.name)
      end
    end

    context "with users in param" do
      it "paginates top users across sitemap pages", :aggregate_failures do
        stub_const("SitemapsController::RESULTS_LIMIT", 1)
        top_user = create(:user, comments_count: 200)
        second_user = create(:user, comments_count: 100)

        get "/sitemap-users.xml"
        expect(response.body).to include(top_user.username)
        expect(response.body).not_to include(second_user.username)

        get "/sitemap-users-1.xml"
        expect(response.body).not_to include(top_user.username)
        expect(response.body).to include(second_user.username)

        get "/sitemap-users-randomn0tnumber.xml"
        expect(response.body).to include(top_user.username)
        expect(response.body).not_to include(second_user.username)

        get "/sitemap-users-2.xml"
        expect(response.body).not_to include(top_user.username, second_user.username)
      end
    end
  end

  context "when requested on a custom domain organization" do
    let(:organization) { create(:organization, custom_domain: "blog.mlh.com") }
    let(:org_article) { create(:article, organization: organization, score: 10) }
    let(:other_article) { create(:article, score: 10) }

    before do
      allow(Settings::General).to receive(:app_domain).and_return("forem.com")
      FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor.new(organization))
    end

    describe "GET /sitemap-index.xml" do
      it "renders the sitemap index with only the organization's posts sitemap and no users/tags sitemaps" do
        get "http://blog.mlh.com/sitemap-index.xml"

        expect(response.body).to include("<sitemapindex xmlns=")
        expect(response.body).to include("http://blog.mlh.com/sitemap-posts.xml")
        expect(response.body).not_to include("sitemap-users.xml")
        expect(response.body).not_to include("sitemap-tags.xml")
      end
    end

    describe "GET /sitemap-posts.xml" do
      it "renders the posts sitemap with only the organization's articles using the custom domain paths" do
        org_article
        other_article
        get "http://blog.mlh.com/sitemap-posts.xml"

        expect(response.body).to include("http://blog.mlh.com/#{org_article.slug}")
        expect(response.body).not_to include(org_article.path)
        expect(response.body).not_to include(other_article.slug)
      end
    end

    describe "GET other resource sitemaps" do
      it "redirects users sitemap to the main domain" do
        get "http://blog.mlh.com/sitemap-users.xml"
        expect(response).to redirect_to("http://forem.com/sitemap-users.xml")
      end

      it "redirects tags sitemap to the main domain" do
        get "http://blog.mlh.com/sitemap-tags.xml"
        expect(response).to redirect_to("http://forem.com/sitemap-tags.xml")
      end

      it "redirects monthly sitemaps to the main domain" do
        get "http://blog.mlh.com/sitemap-Mar-2020.xml"
        expect(response).to redirect_to("http://forem.com/sitemap-Mar-2020.xml")
      end
    end
  end
end
