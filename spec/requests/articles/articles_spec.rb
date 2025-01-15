require "rails_helper"

RSpec.describe "Articles" do
  let(:user) { create(:user) }
  let(:tag)  { build_stubbed(:tag) }

  describe "GET /feed(/:username|/:tag_name)" do
    it "returns rss+xml content" do
      create(:article, featured: true)

      get feed_path

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/xml")
    end

    it "contains the full app URL" do
      create(:article, featured: true)

      get feed_path

      expect(response.body).to include("<link>#{URL.url}</link>")
    end

    it "returns not found if no articles", :aggregate_failures do
      expect { get feed_path }.to raise_error(ActiveRecord::RecordNotFound)
      expect { get user_feed_path(user.username) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { get tag_feed_path(tag.name) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not contain image tag" do
      create(:article, featured: true)

      get feed_path

      expect(response.body).not_to include("<image>")
    end

    context "with caching headers" do
      let!(:article) { create(:article, featured: true) }
      before do
        get feed_path
      end

      it "sets Fastly Cache-Control headers" do
        expected_cache_control_headers = %w[public no-cache]
        expect(response.headers["Cache-Control"].split(", ")).to match_array(expected_cache_control_headers)
      end

      it "sets Fastly Surrogate-Control headers" do
        expected_surrogate_control_headers = %w[max-age=600 stale-while-revalidate=30 stale-if-error=86400]
        expect(response.headers["Surrogate-Control"].split(", ")).to match_array(expected_surrogate_control_headers)
      end

      it "sets Fastly Surrogate-Key headers" do
        expected_surrogate_key_headers = [" articles/#{article.id}"]
        expect(response.headers["Surrogate-Key"].split(", ")).to match_array(expected_surrogate_key_headers)
      end

      it "sets Nginx X-Accel-Expires headers" do
        expect(response.headers["X-Accel-Expires"]).to eq("600")
      end
    end

    context "when :username param is not given" do
      let!(:featured_article) { create(:article, featured: true) }
      let!(:not_featured_article) do
        create(:article, featured: false, score: Settings::UserExperience.home_feed_minimum_score - 1)
      end

      before { get feed_path }

      it "returns only featured articles", :aggregate_failures do
        expect(response.body).to include(featured_article.title)
        expect(response.body).not_to include(not_featured_article.title)
      end
    end

    shared_context "when user/organization articles exist" do
      let(:user) { create(:user) }
      let(:organization) { create(:organization) }
    end

    context "when :username param is given and belongs to a user" do
      include_context "when user/organization articles exist"

      let!(:user_article) { create(:article, user: user) }
      let!(:organization_article) { create(:article, organization: organization) }

      before { get user_feed_path(user.username) }

      it "returns only articles for that user", :aggregate_failures do
        expect(response.body).to include(user_article.title)
        expect(response.body).not_to include(organization_article.title)
      end

      it "contains user's name, link, and composite profile image tag" do
        expect(response.body).to include(
          "<image>",
          "<url>#{app_url(user.profile_image_90)}</url>",
          "<title>#{community_name}: #{user.name}</title>",
          "<link>#{URL.user(user)}</link>",
          "</image>",
          "<dc:creator>#{user.name}</dc:creator>",
        )
      end
    end

    context "when :username param is given and belongs to an organization" do
      include_context "when user/organization articles exist"

      let!(:user_article) { create(:article, user: user) }
      let!(:organization_article) { create(:article, organization: organization) }

      before { get user_feed_path(organization.slug) }

      it "returns only articles for that organization", :aggregate_failures do
        expect(response.body).not_to include(user_article.title)
        expect(response.body).to include(organization_article.title)
      end

      it "contains the full organization URL" do
        expect(response.body).to include("<link>#{URL.organization(organization)}</link>")
      end

      it "contains an organization composite profile image tag", :aggregate_failures do
        expect(response.body).to include("<image>")
        expect(response.body).to include("<url>#{app_url(organization.profile_image_90)}</url>")
        expect(response.body).to include("<title>#{community_name}: #{organization.name}</title>")
        expect(response.body).to include("<link>#{URL.user(organization)}</link>")
        expect(response.body).to include("</image>")
      end
    end

    context "when :username param is given but it belongs to neither user nor organization" do
      it "renders empty body" do
        expect do
          get user_feed_path("unknown")
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when format is invalid" do
      it "returns a 404 response" do
        expect { get "/feed.zip" }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it "contains tags as categories" do
      article = create(:article, featured: true)

      get feed_path

      rss_feed = Feedjira.parse(response.body)
      expect(rss_feed.entries.first.categories).to match_array(article.tag_list)
    end

    context "with scored articles" do
      before do
        allow(Settings::UserExperience).to receive(:home_feed_minimum_score).and_return(10)
      end

      it "does not contain non featured articles with a score below Settings::UserExperience.home_feed_minimum_score" do
        create(:article, featured: false, score: Settings::UserExperience.home_feed_minimum_score - 1)

        expect { get feed_path }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "contains non featured articles with a score equal to Settings::UserExperience.home_feed_minimum_score" do
        create(:article, featured: false, score: Settings::UserExperience.home_feed_minimum_score)

        get feed_path

        expect(response).to have_http_status(:ok)
      end

      it "contains non featured articles with a score above Settings::UserExperience.home_feed_minimum_score" do
        create(:article, featured: false, score: Settings::UserExperience.home_feed_minimum_score + 1)

        get feed_path

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /feed/latest" do
    let!(:last_article) { create(:article, featured: true) }
    let!(:not_featured_article) { create(:article, featured: false) }
    let!(:article_with_low_score) { create(:article, score: Articles::Feeds::Latest::MINIMUM_SCORE) }
    let!(:article_with_mid_score) { create(:article, score: Settings::UserExperience.home_feed_minimum_score) }

    before { get "/feed/latest" }

    it "contains latest articles" do
      expect(response.body).to include(last_article.title, not_featured_article.title, article_with_mid_score.title)
      expect(response.body).not_to include(article_with_low_score.title)
    end
  end

  describe "GET /feed/tag" do
    context "when :tag param is given and tag exists" do
      before do
        create(:article, tags: tag.name)
      end

      it "returns only articles for that tag" do
        article = create(:article, tags: ["foobar"])
        # tag_article = create(:article, tags: tag.name)

        get tag_feed_path(tag.name)

        rss_feed = Feedjira.parse(response.body)
        titles = rss_feed.entries.map(&:title)

        expect(titles).not_to include(article.title)

        tag_article = Article.cached_tagged_with(tag.name).take
        expect(titles).to include(tag_article.title)
      end

      it "contains the tag as a category" do
        get tag_feed_path(tag.name)

        rss_feed = Feedjira.parse(response.body)
        expect(rss_feed.entries.first.categories).to include(tag.name)
      end

      it "contains the full tag URL" do
        get tag_feed_path(tag.name)

        expect(response.body).to include("<link>#{tag_url(tag)}</link>")
      end

      it "does not contain image tag" do
        get tag_feed_path(tag.name)

        expect(response.body).not_to include("<image>")
      end
    end

    context "when :tag param is given and tag exists and is an alias" do
      before do
        create(:article, tags: tag.name)
        alias_tag = create(:tag, alias_for: tag.name)
        get "/feed/tag/#{alias_tag.name}"
      end

      it "returns only articles for the aliased for tag" do
        tag_article = Article.cached_tagged_with(tag.name).take

        expect(response.body).to include(tag_article.title)
      end
    end

    context "when :tag param is given and tag does not exist" do
      it "renders empty body" do
        expect { get "/feed/tag/unknown" }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "GET /new" do
    before { sign_in user }

    context "with authorized user" do
      it "returns a new article" do
        get "/new"
        expect(response).to have_http_status(:ok)
      end
    end

    context "with authorized user with tag param" do
      it "returns a new article" do
        get "/new", params: { slug: "mytag" }
        expect(response).to have_http_status(:ok)
      end
    end

    it "sets canonical url with base" do
      get "/new"
      expect(response.body).to include('<link rel="canonical" href="http://forem.test/new" />')
    end

    it "sets canonical url with prefill" do
      get "/new?prefill=dsdweewewew"
      expect(response.body).to include('<link rel="canonical" href="http://forem.test/new" />')
    end
  end

  describe "GET /:path/edit" do
    before { sign_in user }

    it "shows v1 if article has frontmatter" do
      article = create(:article, user_id: user.id)
      get "#{article.path}/edit"
      expect(response.body).to include("crayons-article-form--v1")
    end
  end

  describe "GET /:path/manage" do
    before { sign_in user }

    it "works successfully" do
      article = create(:article, user: user)
      get "#{article.path}/manage"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Manage Your Post")
    end

    it "returns unauthorized for a draft" do
      draft = create(:article, published: false, user: user)
      expect { get "#{draft.path}/manage" }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "returns unauthorized for a scheduled article" do
      scheduled_article = create(:article, published: true, user: user, published_at: 1.day.from_now)
      expect { get "#{scheduled_article.path}/manage" }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "returns unauthorized if the user is not the author" do
      second_user = create(:user)
      article = create(:article, user: second_user)
      expect { get "#{article.path}/manage" }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "GET /:path/stats" do
    before { sign_in user }

    it "returns unauthorized if the user is not the author" do
      second_user = create(:user)
      article = create(:article, user: second_user)
      expect { get "#{article.path}/stats" }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "works successfully" do
      article = create(:article, user: user)
      get "#{article.path}/stats"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Stats for Your Article")
    end
  end
end
