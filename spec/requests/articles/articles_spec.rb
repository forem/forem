require "rails_helper"

RSpec.describe "Articles" do
  let(:user) { create(:user, :without_profile) }
  let(:tag)  { build_stubbed(:tag) }

  def create_test_article(**attrs)
    defaults = {
      user: user,
      with_main_image: false,
      with_tags: attrs.key?(:tags)
    }
    create(:article, **defaults, **attrs)
  end

  describe "GET /feed(/:username|/:tag_name)" do
    it "returns rss+xml content with the full app URL, tag categories, and no image tag", :aggregate_failures do
      article = create_test_article(featured: true, with_tags: true)

      get feed_path

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/xml")
      expect(response.body).to include("<link>#{URL.url}</link>")
      expect(response.body).not_to include("<image>")

      rss_feed = Feedjira.parse(response.body)
      expect(rss_feed.entries.first.categories).to match_array(article.tag_list)
    end

    it "returns not found if no articles", :aggregate_failures do
      expect { get feed_path }.to raise_error(ActiveRecord::RecordNotFound)
      expect { get user_feed_path(user.username) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { get tag_feed_path(tag.name) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "with caching headers" do
      let!(:article) { create_test_article(featured: true) }

      before do
        get feed_path
      end

      it "sets Fastly and Nginx caching headers", :aggregate_failures do
        expected_cache_control_headers = %w[public no-cache]
        expect(response.headers["Cache-Control"].split(", ")).to match_array(expected_cache_control_headers)

        expected_surrogate_control_headers = %w[max-age=600 stale-while-revalidate=30 stale-if-error=86400]
        expect(response.headers["Surrogate-Control"].split(", ")).to match_array(expected_surrogate_control_headers)

        expected_surrogate_key_headers = ["articles/#{article.id}"]
        expect(response.headers["Surrogate-Key"].split).to match_array(expected_surrogate_key_headers)

        expect(response.headers["X-Accel-Expires"]).to eq("600")
      end
    end

    context "when :username param is not given" do
      let!(:featured_article) { create_test_article(featured: true) }
      let!(:not_featured_article) do
        create_test_article(featured: false, score: Settings::UserExperience.home_feed_minimum_score - 1)
      end

      before { get feed_path }

      it "returns only featured articles", :aggregate_failures do
        expect(response.body).to include(featured_article.title)
        expect(response.body).not_to include(not_featured_article.title)
      end
    end

    shared_context "when user/organization articles exist" do
      let(:user) { create(:user, :without_profile) }
      let(:organization) { create(:organization) }
    end

    context "when :username param is given and belongs to a user" do
      include_context "when user/organization articles exist"

      let(:other_user) { create(:user, :without_profile) }
      let!(:user_article) { create_test_article(user: user) }
      let!(:organization_article) { create_test_article(user: other_user, organization: organization) }

      before { get user_feed_path(user.username) }

      it "returns only articles for that user with name, link, and composite profile image tag", :aggregate_failures do
        expect(response.body).to include(user_article.title)
        expect(response.body).not_to include(organization_article.title)
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

      let!(:user_article) { create_test_article(user: user) }
      let!(:organization_article) { create_test_article(user: user, organization: organization) }

      before { get user_feed_path(organization.slug) }

      it "returns only articles for that organization with URL and composite profile image tag", :aggregate_failures do
        expect(response.body).not_to include(user_article.title)
        expect(response.body).to include(organization_article.title)
        expect(response.body).to include("<link>#{URL.organization(organization)}</link>")
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

    context "with scored articles" do
      before do
        allow(Settings::UserExperience).to receive(:home_feed_minimum_score).and_return(10)
      end

      it "does not contain non featured articles with a score below Settings::UserExperience.home_feed_minimum_score" do
        create_test_article(featured: false, score: Settings::UserExperience.home_feed_minimum_score - 1)

        expect { get feed_path }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "contains non featured articles with a score at or above Settings::UserExperience.home_feed_minimum_score",
         :aggregate_failures do
        equal_score_article = create_test_article(featured: false,
                                                  score: Settings::UserExperience.home_feed_minimum_score)
        above_score_article = create_test_article(featured: false,
                                                  score: Settings::UserExperience.home_feed_minimum_score + 1)

        get feed_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(equal_score_article.title, above_score_article.title)
      end
    end
  end

  describe "GET /feed/latest" do
    let!(:last_article) { create_test_article(featured: true) }
    let!(:not_featured_article) { create_test_article(featured: false) }
    let!(:article_with_low_score) { create_test_article(score: Articles::Feeds::Latest::MINIMUM_SCORE) }
    let!(:article_with_mid_score) do
      create_test_article(score: Settings::UserExperience.home_feed_minimum_score)
    end

    before { get "/feed/latest" }

    it "contains latest articles" do
      expect(response.body).to include(last_article.title, not_featured_article.title, article_with_mid_score.title)
      expect(response.body).not_to include(article_with_low_score.title)
    end
  end

  describe "GET /feed/tag" do
    context "when :tag param is given and tag exists" do
      it "returns only articles for that tag with category, full tag URL, and no image tag", :aggregate_failures do
        tag_article = create_test_article(tags: tag.name)
        other_article = create_test_article(tags: ["foobar"])

        get tag_feed_path(tag.name)

        rss_feed = Feedjira.parse(response.body)
        titles = rss_feed.entries.map(&:title)

        expect(titles).not_to include(other_article.title)
        expect(titles).to include(tag_article.title)
        expect(rss_feed.entries.first.categories).to include(tag.name)
        expect(response.body).to include("<link>#{tag_url(tag)}</link>")
        expect(response.body).not_to include("<image>")
      end

      it "preloads article authors instead of loading each one separately" do
        authors = create_list(:user, 2, :without_profile)
        authors.each { |author| create_test_article(user: author, tags: tag.name) }

        user_lookups = []
        callback = lambda do |*, payload|
          user_lookups << payload[:sql] if payload[:sql].match?(/FROM "users" WHERE "users"."id" = /)
        end
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { get tag_feed_path(tag.name) }

        rss_feed = Feedjira.parse(response.body)
        expect(rss_feed.entries.map(&:author)).to include(*authors.map(&:name))
        expect(user_lookups).to be_empty
      end
    end

    context "when :tag param is given and tag exists and is an alias" do
      before do
        create_test_article(tags: tag.name)
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
      it "returns a new article with canonical url and without querying tags when template param is absent",
         :aggregate_failures do
        tag_queries = []
        callback = lambda do |*, payload|
          tag_queries << payload[:sql] if payload[:sql].match?(/FROM "tags" WHERE "tags"."name"/)
        end
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { get "/new" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('<link rel="canonical" href="http://forem.test/new" />')
        expect(tag_queries).to be_empty
      end
    end

    context "with authorized user with tag param" do
      it "returns a new article" do
        get "/new", params: { slug: "mytag" }
        expect(response).to have_http_status(:ok)
      end
    end

    context "with the template param" do
      it "prefills the editor from the matching tag without hydrating full tag columns", :aggregate_failures do
        tag = create(:tag, name: "templatetag")
        tag_queries = []
        callback = lambda do |*, payload|
          tag_queries << payload[:sql] if payload[:sql].match?(/FROM "tags" WHERE "tags"."name"/)
        end
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          get "/new", params: { template: tag.name }
        end

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("templatetag")
        expect(tag_queries.size).to eq(1)
        expect(tag_queries.first).to include('"tags"."id", "tags"."name", "tags"."submission_template"')
        expect(tag_queries.first).not_to include('"tags".*')
      end

      it "skips querying tags when visitor is signed out", :aggregate_failures do
        sign_out user
        tag = create(:tag, name: "templatetag")
        tag_queries = []
        callback = lambda do |*, payload|
          tag_queries << payload[:sql] if payload[:sql].match?(/FROM "tags" WHERE "tags"."name"/)
        end
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          get "/new/#{tag.name}"
        end

        expect(response).to have_http_status(:ok)
        expect(tag_queries).to be_empty
      end
    end

    it "sets canonical url with prefill" do
      get "/new?prefill=dsdweewewew"
      expect(response.body).to include('<link rel="canonical" href="http://forem.test/new" />')
    end
  end

  describe "GET /:path/edit" do
    before { sign_in user }

    it "shows v1 if article has frontmatter" do
      article = create_test_article
      get "#{article.path}/edit"
      expect(response.body).to include("crayons-article-form--v1")
    end
  end

  describe "GET /:path/manage" do
    before { sign_in user }

    it "works successfully, masks page views at or below 25, and shows exact views above 25", :aggregate_failures do
      article = create_test_article
      article.update_column(:page_views_count, 25)
      get "#{article.path}/manage"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Manage Your Post")
      expect(response.body).to include(CGI.escapeHTML(I18n.t("views.dashboard.article.views.lt_25")))

      article.update_column(:page_views_count, 1234)
      get "#{article.path}/manage"
      expect(response.body).to include("1,234")
      expect(response.body).not_to include(CGI.escapeHTML(I18n.t("views.dashboard.article.views.lt_25")))
    end

    it "returns unauthorized for a draft or scheduled article", :aggregate_failures do
      article = create_test_article(published: false)
      expect { get "#{article.path}/manage" }.to raise_error(Pundit::NotAuthorizedError)

      article.update_columns(published: true, published_at: 1.day.from_now)
      expect { get "#{article.path}/manage" }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "returns unauthorized if the user is not the author" do
      second_user = create(:user, :without_profile)
      article = create_test_article(user: second_user)
      expect { get "#{article.path}/manage" }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "GET /:path/stats" do
    before { sign_in user }

    it "returns unauthorized if the user is not the author" do
      second_user = create(:user, :without_profile)
      article = create_test_article(user: second_user)
      expect { get "#{article.path}/stats" }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "works successfully" do
      article = create_test_article
      get "#{article.path}/stats"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Stats for Your Article")
    end
  end
end
