require "rails_helper"

RSpec.describe "Api::V0::Articles", type: :request do
  let(:organization) { create(:organization) } # not used by every spec but lower times overall
  let(:tag) { create(:tag, name: "discuss") }
  let(:article) { create(:article, featured: true, tags: "discuss") }

  before { stub_const("FlareTag::FLARE_TAG_IDS_HASH", { "discuss" => tag.id }) }

  describe "GET /api/articles" do
    before { article }

    it "returns CORS headers" do
      origin = "http://example.com"
      get api_articles_path, headers: { origin: origin }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Access-Control-Allow-Origin"]).to eq(origin)
      expect(response.headers["Access-Control-Allow-Methods"]).to eq("HEAD, GET, OPTIONS")
      expect(response.headers["Access-Control-Expose-Headers"]).to be_empty
      expect(response.headers["Access-Control-Max-Age"]).to eq(2.hours.to_i.to_s)
    end

    it "has correct keys in the response" do
      article.update_columns(organization_id: organization.id)
      get api_articles_path

      index_keys = %w[
        type_of id title description cover_image readable_publish_date social_image
        tag_list tags slug path url canonical_url comments_count public_reactions_count positive_reactions_count
        collection_id created_at edited_at crossposted_at published_at last_comment_at
        published_timestamp user organization flare_tag
      ]

      expect(response.parsed_body.first.keys).to match_array index_keys
    end

    it "returns correct tag list" do
      get api_articles_path

      expect(response.parsed_body.first["tag_list"]).to be_a_kind_of Array
    end

    it "returns correct tags" do
      get api_articles_path

      expect(response.parsed_body.first["tags"]).to be_a_kind_of String
    end

    context "without params" do
      it "returns json response" do
        get api_articles_path
        expect(response.media_type).to eq("application/json")
      end

      it "returns nothing if params state=all is not found" do
        get api_articles_path(state: "all")
        expect(response.parsed_body.size).to eq(0)
      end

      it "returns featured articles if no param is given" do
        article.update_column(:featured, true)
        get api_articles_path
        expect(response.parsed_body.size).to eq(1)
      end

      it "supports pagination" do
        create_list(:article, 2, featured: true)
        get api_articles_path, params: { page: 1, per_page: 2 }
        expect(response.parsed_body.length).to eq(2)
        get api_articles_path, params: { page: 2, per_page: 2 }
        expect(response.parsed_body.length).to eq(1)
      end

      it "returns flare tag in the response" do
        get api_articles_path
        response_article = response.parsed_body.first
        expect(response_article["flare_tag"]).to be_present
        expect(response_article["flare_tag"].keys).to eq(%w[name bg_color_hex text_color_hex])
        expect(response_article["flare_tag"]["name"]).to eq("discuss")
      end

      it "sets the correct edge caching surrogate key" do
        get api_articles_path

        expected_key = ["articles", article.record_key].to_set
        expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
      end
    end

    context "with username param" do
      it "returns user's articles for the given username" do
        create(:article, user: article.user)
        get api_articles_path(username: article.user.username)
        expect(response.parsed_body.size).to eq(2)
      end

      it "returns nothing if given user is not found" do
        get api_articles_path(username: "foobar")
        expect(response.parsed_body.size).to eq(0)
      end

      it "returns org's articles if org's slug is given" do
        create(:article, user: article.user, organization: organization)
        get api_articles_path(username: organization.slug)
        expect(response.parsed_body.size).to eq(1)
      end

      it "supports pagination" do
        create_list(:article, 2, user: article.user)
        get api_articles_path(username: article.user.username), params: { page: 1, per_page: 2 }
        expect(response.parsed_body.length).to eq(2)
        get api_articles_path(username: article.user.username), params: { page: 2, per_page: 2 }
        expect(response.parsed_body.length).to eq(1)
      end

      it "sets the correct edge caching surrogate key" do
        new_article = create(:article, user: article.user)
        get api_articles_path(username: article.user.username)

        expected_key = ["articles", article.record_key, new_article.record_key].to_set
        expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
      end
    end

    context "with tag param" do
      it "returns tag's articles" do
        get api_articles_path(tag: article.tag_list.first)
        expect(response.parsed_body.size).to eq(1)
      end

      it "returns top tag articles if tag and top param is present" do
        get api_articles_path(tag: article.tag_list.first, top: "7")
        expect(response.parsed_body.size).to eq(1)
      end

      it "returns not tag articles if article and tag are not approved" do
        article.update_column(:approved, false)
        tag = Tag.find_by(name: article.tag_list.first)
        tag.update(requires_approval: true)

        get api_articles_path(tag: tag.name)
        expect(response.parsed_body.size).to eq(0)
      end

      it "supports pagination" do
        create_list(:article, 2, tags: "discuss")
        get api_articles_path(tag: article.tag_list.first), params: { page: 1, per_page: 2 }
        expect(response.parsed_body.length).to eq(2)
        get api_articles_path(tag: article.tag_list.first), params: { page: 2, per_page: 2 }
        expect(response.parsed_body.length).to eq(1)
      end

      it "sets the correct edge caching surrogate key" do
        get api_articles_path(tag: article.tag_list.first)

        expected_key = ["articles", article.record_key].to_set
        expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
      end
    end

    context "with tags param" do
      it "returns articles with any of the specified tags" do
        create(:article, published: true)
        get api_articles_path(tags: "javascript, css, not-existing-tag")
        expect(response.parsed_body.size).to eq(1)
      end
    end

    context "with tags_exclude param" do
      it "returns articles that do not contain any of excluded tag" do
        create(:article, published: true)
        get api_articles_path(tags_exclude: "node, java")
        expect(response.parsed_body.size).to eq(2)

        create(:article, published: true, tags: "node")
        get api_articles_path(tags_exclude: "node, java")
        expect(response.parsed_body.size).to eq(2)
      end
    end

    context "with tags and tags_exclude params" do
      it "returns proper scope" do
        create(:article, published: true)
        get api_articles_path(tags: "javascript, css", tags_exclude: "node, java")
        expect(response.parsed_body.size).to eq(1)
      end
    end

    context "when tags and tags_exclude contain the same tag" do
      it "returns empty set" do
        create(:article, published: true, tags: "java")
        get api_articles_path(tags: "java", tags_exclude: "java")
        expect(response.parsed_body.size).to eq(0)
      end
    end

    context "with top param" do
      it "only returns fresh top articles if top param is present" do
        # TODO: slight duplication, test should be removed
        old_article = create(:article)
        old_article.update_column(:published_at, 10.days.ago)
        get api_articles_path(top: "7")
        expect(response.parsed_body.size).to eq(1)
      end

      it "supports pagination" do
        old_articles = create_list(:article, 2, featured: true)
        old_articles.each do |old_article|
          old_article.update_column(:published_at, 10.days.ago)
        end
        get api_articles_path(top: "11"), params: { page: 1, per_page: 2 }
        expect(response.parsed_body.length).to eq(2)
        get api_articles_path(top: "11"), params: { page: 2, per_page: 2 }
        expect(response.parsed_body.length).to eq(1)
      end

      it "sets the correct edge caching surrogate key" do
        get api_articles_path(top: "7")

        expected_key = ["articles", article.record_key].to_set
        expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
      end
    end

    context "with collection_id param" do
      it "returns a collection id" do
        collection = create(:collection, user: article.user)
        article.update_columns(collection_id: collection.id)
        get api_articles_path(collection_id: collection.id)
        expect(response.parsed_body[0]["collection_id"]).to eq collection.id
      end

      it "supports pagination" do
        collection = create(:collection, user: article.user)
        article.update_columns(collection_id: collection.id)
        collection_articles = create_list(:article, 2, featured: true)
        collection_articles.each do |collection_article|
          collection_article.update_columns(collection_id: collection.id)
        end
        get api_articles_path(collection_id: collection.id), params: { page: 1, per_page: 2 }
        expect(response.parsed_body.length).to eq(2)
        get api_articles_path(collection_id: collection.id), params: { page: 2, per_page: 2 }
        expect(response.parsed_body.length).to eq(1)
      end

      it "sets the correct edge caching surrogate key" do
        collection = create(:collection, user: article.user)
        article.update_columns(collection_id: collection.id)
        get api_articles_path(collection_id: collection.id)

        expected_key = ["articles", article.record_key].to_set
        expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
      end
    end

    context "with state param" do
      it "returns fresh articles" do
        article.update_columns(public_reactions_count: 1, score: 1)

        get api_articles_path(state: "fresh")
        expect(response.parsed_body.size).to eq(1)
      end

      it "returns rising articles" do
        article.update_columns(public_reactions_count: 32, score: 1, featured_number: 2.days.ago.to_i)

        get api_articles_path(state: "rising")
        expect(response.parsed_body.size).to eq(1)
      end

      it "returns nothing if the state is unknown" do
        get api_articles_path(state: "foobar")

        expect(response.parsed_body).to be_empty
      end

      it "supports pagination" do
        create_list(:article, 2, tags: "discuss", public_reactions_count: 1, score: 1)

        get api_articles_path(state: "fresh"), params: { page: 1, per_page: 2 }
        expect(response.parsed_body.length).to eq(2)
        get api_articles_path(state: "fresh"), params: { page: 2, per_page: 2 }
        expect(response.parsed_body.length).to eq(1)
      end

      it "sets the correct edge caching surrogate key" do
        article.update_columns(public_reactions_count: 1, score: 1)

        get api_articles_path(state: "fresh")
        expected_key = ["articles", article.record_key].to_set
        expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
      end
    end

    context "with regression tests" do
      it "works if both the social image and the main image are missing" do
        article.update_columns(social_image: nil, main_image: nil)

        get api_articles_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /api/articles/:id" do
    it "returns CORS headers" do
      origin = "http://example.com"
      get api_article_path(article.id), headers: { origin: origin }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Access-Control-Allow-Origin"]).to eq(origin)
      expect(response.headers["Access-Control-Allow-Methods"]).to eq("HEAD, GET, OPTIONS")
      expect(response.headers["Access-Control-Expose-Headers"]).to be_empty
      expect(response.headers["Access-Control-Max-Age"]).to eq(2.hours.to_i.to_s)
    end

    it "has correct keys in the response" do
      article.update_columns(organization_id: organization.id)
      get api_article_path(article.id)

      show_keys = %w[
        type_of id title description cover_image readable_publish_date social_image
        tag_list tags slug path url canonical_url comments_count public_reactions_count positive_reactions_count
        collection_id created_at edited_at crossposted_at published_at last_comment_at
        published_timestamp body_html body_markdown user organization flare_tag
      ]

      expect(response.parsed_body.keys).to match_array show_keys
    end

    it "returns correct tag list" do
      get api_article_path(article.id)

      expect(response.parsed_body["tag_list"]).to be_a_kind_of String
    end

    it "returns correct tags" do
      get api_article_path(article.id)

      expect(response.parsed_body["tags"]).to be_a_kind_of Array
    end

    it "returns proper article" do
      get api_article_path(article.id)
      expect(response.parsed_body).to include(
        "title" => article.title,
        "body_markdown" => article.body_markdown,
        "tags" => article.decorate.cached_tag_list_array,
      )
    end

    it "returns all the relevant datetimes" do
      article.update_columns(
        edited_at: 1.minute.from_now, crossposted_at: 2.minutes.ago, last_comment_at: 30.seconds.ago,
      )
      get api_article_path(article.id)
      expect(response.parsed_body).to include(
        "created_at" => article.created_at.utc.iso8601,
        "edited_at" => article.edited_at.utc.iso8601,
        "crossposted_at" => article.crossposted_at.utc.iso8601,
        "published_at" => article.published_at.utc.iso8601,
        "last_comment_at" => article.last_comment_at.utc.iso8601,
      )
    end

    it "fails with an unpublished article" do
      article.update_columns(published: false)
      get api_article_path(article.id)
      expect(response).to have_http_status(:not_found)
    end

    it "fails with an unknown article ID" do
      get api_article_path("9999")
      expect(response).to have_http_status(:not_found)
    end

    it "sets the correct edge caching surrogate key" do
      get api_article_path(article)

      expected_key = [article.record_key].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
    end
  end

  describe "GET /api/articles/:username/:slug" do
    it "returns CORS headers" do
      origin = "http://example.com"
      get slug_api_articles_path(article.username, article.slug), headers: { origin: origin }
      expect(response).to have_http_status(:ok)
      expect(response.headers["Access-Control-Allow-Origin"]).to eq(origin)
      expect(response.headers["Access-Control-Allow-Methods"]).to eq("HEAD, GET, OPTIONS")
      expect(response.headers["Access-Control-Expose-Headers"]).to be_empty
      expect(response.headers["Access-Control-Max-Age"]).to eq(2.hours.to_i.to_s)
    end

    it "returns correct tags" do
      get slug_api_articles_path(username: article.username, slug: article.slug)
      expect(response.parsed_body["tags"]).to eq(article.tag_list)
      expect(response.parsed_body["tag_list"]).to eq(article.tags[0].name)
    end

    it "returns proper article" do
      get slug_api_articles_path(username: article.username, slug: article.slug)
      expect(response.parsed_body).to include(
        "title" => article.title,
        "body_markdown" => article.body_markdown,
        "tags" => article.decorate.cached_tag_list_array,
      )
    end

    it "returns all the relevant datetimes" do
      article.update_columns(
        edited_at: 1.minute.from_now, crossposted_at: 2.minutes.ago, last_comment_at: 30.seconds.ago,
      )
      get slug_api_articles_path(username: article.username, slug: article.slug)
      expect(response.parsed_body).to include(
        "created_at" => article.created_at.utc.iso8601,
        "edited_at" => article.edited_at.utc.iso8601,
        "crossposted_at" => article.crossposted_at.utc.iso8601,
        "published_at" => article.published_at.utc.iso8601,
        "last_comment_at" => article.last_comment_at.utc.iso8601,
      )
    end

    it "fails with an unpublished article" do
      article.update_columns(published: false)
      get slug_api_articles_path(username: article.username, slug: article.slug)
      expect(response).to have_http_status(:not_found)
    end

    it "fails with an unknown article path" do
      get slug_api_articles_path(username: "chris evan", slug: article.slug)
      expect(response).to have_http_status(:not_found)
    end

    it "sets the correct edge caching surrogate key" do
      get slug_api_articles_path(username: article.username, slug: article.slug)

      expected_key = [article.record_key].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
    end
  end

  describe "GET /api/articles/me(/:status)" do
    context "when request is unauthenticated" do
      let(:user) { create(:user) }
      let(:public_token) { create :doorkeeper_access_token, resource_owner: user, scopes: "public" }

      it "return unauthorized" do
        get me_api_articles_path
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns forbidden when requesting for all with only public scope" do
        get me_api_articles_path(status: :all), params: { access_token: public_token.token }
        expect(response).to have_http_status(:forbidden)
      end

      it "returns forbidden status when requesting unpublished with public scope" do
        get me_api_articles_path(status: :unpublished), params: { access_token: public_token.token }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when request is authenticated" do
      let(:user) { create(:user) }
      let(:access_token) { create :doorkeeper_access_token, resource_owner: user, scopes: "public read_articles" }

      it "works with bearer authorization" do
        headers = { "authorization" => "Bearer #{access_token.token}", "content-type" => "application/json" }

        get me_api_articles_path, headers: headers
        expect(response.media_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end

      it "returns proper response specification" do
        get me_api_articles_path, params: { access_token: access_token.token }
        expect(response.media_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end

      it "returns success when requesting published articles with public token" do
        public_token = create(:doorkeeper_access_token, resource_owner: user, scopes: "public")
        get me_api_articles_path(status: :published), params: { access_token: public_token.token }
        expect(response.media_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end

      it "return only user's articles including markdown" do
        create(:article, user: user)
        create(:article)
        get me_api_articles_path, params: { access_token: access_token.token }
        expect(response.parsed_body.length).to eq(1)
        expect(response.parsed_body[0]["body_markdown"]).not_to be_nil
      end

      it "supports pagination" do
        create_list(:article, 3, user: user)
        get me_api_articles_path, params: { access_token: access_token.token, page: 2, per_page: 2 }
        expect(response.parsed_body.length).to eq(1)
      end

      it "only includes published articles by default" do
        create(:article, published: false, published_at: nil, user: user)
        get me_api_articles_path, params: { access_token: access_token.token }
        expect(response.parsed_body.length).to eq(0)
      end

      it "only includes published articles when asking for published articles" do
        create(:article, published: false, published_at: nil, user: user)
        get me_api_articles_path(status: :published), params: { access_token: access_token.token }
        expect(response.parsed_body.length).to eq(0)
      end

      it "only includes unpublished articles when asking for unpublished articles" do
        create(:article, published: false, published_at: nil, user: user)
        get me_api_articles_path(status: :unpublished), params: { access_token: access_token.token }
        expect(response.parsed_body.length).to eq(1)
      end

      it "orders unpublished articles by reverse order when asking for unpublished articles" do
        older = create(:article, published: false, published_at: nil, user: user)
        newer = nil
        Timecop.travel(1.day.from_now) do
          newer = create(:article, published: false, published_at: nil, user: user)
        end
        get me_api_articles_path(status: :unpublished), params: { access_token: access_token.token }
        expected_order = response.parsed_body.map { |resp| resp["id"] }
        expect(expected_order).to eq([newer.id, older.id])
      end

      it "puts unpublished articles at the top when asking for all articles" do
        create(:article, user: user)
        create(:article, published: false, published_at: nil, user: user)
        get me_api_articles_path(status: :all), params: { access_token: access_token.token }
        expected_order = response.parsed_body.map { |resp| resp["published"] }
        expect(expected_order).to eq([false, true])
      end
    end
  end

  describe "POST /api/articles" do
    let(:api_secret) { create(:api_secret) }
    let(:user) { api_secret.user }

    context "when unauthorized" do
      it "fails with no api key" do
        post api_articles_path, headers: { "content-type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "fails with a banned user" do
        user.add_role(:banned)
        post api_articles_path, headers: { "api-key" => api_secret.secret, "content-type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "fails with the wrong api key" do
        post api_articles_path, headers: { "api-key" => "foobar", "content-type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "fails with a failing secure compare" do
        allow(ActiveSupport::SecurityUtils)
          .to receive(:secure_compare).and_return(false)
        post api_articles_path, headers: { "api-key" => api_secret.secret, "content-type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe "when authorized" do
      let(:default_params) { { body_markdown: "" } }

      def post_article(**params)
        headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
        params = default_params.merge params
        post api_articles_path, params: { article: params }.to_json, headers: headers
      end

      it "returns a 403 if :write_articles scope is missing (oauth)" do
        access_token = create(:doorkeeper_access_token, resource_owner_id: user.id, scopes: "public")
        headers = { "authorization" => "Bearer #{access_token.token}", "content-type" => "application/json" }

        post api_articles_path, params: { article: { title: Faker::Book.title } }.to_json, headers: headers
        expect(response).to have_http_status(:forbidden)
      end

      it "returns a 201 if :write_articles scope is provided (oauth)" do
        access_token = create(:doorkeeper_access_token, resource_owner_id: user.id, scopes: "write_articles")
        headers = { "authorization" => "Bearer #{access_token.token}", "content-type" => "application/json" }

        post api_articles_path, params: { article: { title: Faker::Book.title,
                                                     body_markdown: "" } }.to_json, headers: headers
        expect(response).to have_http_status(:created)
      end

      it "returns a 429 status code if the rate limit is reached" do
        rate_limit_checker = instance_double(RateLimitChecker)
        retry_after_val = RateLimitChecker::ACTION_LIMITERS.dig(:published_article_creation, :retry_after)
        rate_limit_error = RateLimitChecker::LimitReached.new(retry_after_val)
        allow(RateLimitChecker).to receive(:new).and_return(rate_limit_checker)
        allow(rate_limit_checker).to receive(:check_limit!).and_raise(rate_limit_error)

        post_article

        expect(response).to have_http_status(:too_many_requests)
        expect(response.headers["retry-after"]).to eq(retry_after_val)
      end

      it "fails if no params are given" do
        post_article
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails if missing required params" do
        tags = %w[meta discussion]
        post_article(body_markdown: "Yo ho ho", tags: tags)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to be_present
      end

      it "fails if article contains tags with non-alphanumeric characters" do
        tags = %w[#discuss .help]
        post_article(title: "Test Article Title", tags: tags)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails if params are not a Hash" do
        # Not using the nifty post_article helper method because it expects a Hash
        headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
        string_params = "this_string_is_definitely_not_a_hash"
        post api_articles_path, params: { article: string_params }.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to be_present
      end

      it "fails if params are unwrapped" do
        headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
        post api_articles_path, params: { body_markdown: "Body", title: "Title" }.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to be_present
      end

      it "creates an article belonging to the user" do
        post_article(title: Faker::Book.title)
        expect(response).to have_http_status(:created)
        expect(Article.find(response.parsed_body["id"]).user).to eq(user)
      end

      it "creates an unpublished article by default" do
        post_article(title: Faker::Book.title)
        expect(response).to have_http_status(:created)
        expect(Article.find(response.parsed_body["id"]).published).to be(false)
      end

      it "returns the location of the article" do
        post_article(title: Faker::Book.title)
        expect(response).to have_http_status(:created)
        expect(response.location).not_to be_blank
      end

      it "creates an article with only a title" do
        title = Faker::Book.title
        expect do
          post_article(title: title)
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(response.parsed_body["id"]).title).to eq(title)
      end

      it "creates a published article" do
        title = Faker::Book.title
        expect do
          post_article(title: title, published: true)
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(response.parsed_body["id"]).published).to be(true)
      end

      it "creates an article with a title and the markdown body" do
        body_markdown = "Yo ho ho"
        expect do
          post_article(
            title: Faker::Book.title,
            body_markdown: body_markdown,
          )
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(response.parsed_body["id"]).body_markdown).to eq(body_markdown)
      end

      it "creates an article with a title, body and a list of tags" do
        tags = %w[meta discussion]
        expect do
          post_article(
            title: Faker::Book.title,
            body_markdown: "Yo ho ho",
            tags: tags,
          )
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(response.parsed_body["id"]).cached_tag_list).to eq(tags.join(", "))
      end

      it "creates an unpublished article with the front matter in the body" do
        body_markdown = file_fixture("article_unpublished.txt").read
        expect do
          post_article(body_markdown: body_markdown)
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        article = Article.find(response.parsed_body["id"])
        expect(article.title).to eq("Sample Article")
        expect(article.published).to be(false)
      end

      it "creates published article with the front matter in the body" do
        body_markdown = file_fixture("article_published.txt").read
        expect do
          post_article(body_markdown: body_markdown)
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        article = Article.find(response.parsed_body["id"])
        expect(article.title).to eq("Sample Article")
        expect(article.published).to be(true)
      end

      it "creates an article within a series" do
        series = "a series"
        post_article(
          title: Faker::Book.title,
          body_markdown: "Yo ho ho",
          series: series,
        )
        expect(response).to have_http_status(:created)
        article = Article.find(response.parsed_body["id"])
        expect(article.collection).to eq(Collection.find_by(slug: series))
        expect(article.collection.user).to eq(user)
      end

      it "creates article within a series using the front matter" do
        body_markdown = file_fixture("article_published_series.txt").read
        expect do
          post_article(body_markdown: body_markdown)
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        article = Article.find(response.parsed_body["id"])
        expect(article.collection).to eq(Collection.find_by(slug: "a series"))
        expect(article.collection.user).to eq(user)
      end

      it "creates an article on behalf of an organization" do
        organization = create(:organization)
        create(:organization_membership, user: user, organization: organization)
        expect do
          post_article(
            title: Faker::Book.title,
            organization_id: organization.id,
          )
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(response.parsed_body["id"]).organization).to eq(organization)
      end

      it "creates an article with a main/cover image" do
        image_url = "https://dummyimage.com/100x100"
        expect do
          post_article(
            title: Faker::Book.title,
            body_markdown: "Yo ho ho",
            main_image: image_url,
          )
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(response.parsed_body["id"]).main_image).to eq(image_url)
      end

      it "creates an article with a main/cover image in the front matter" do
        image_url = "https://dummyimage.com/100x100"
        body_markdown = file_fixture("article_published_cover_image.txt").read
        expect do
          post_article(body_markdown: body_markdown)
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(response.parsed_body["id"]).main_image).to eq(image_url)
      end

      it "creates an article with a canonical url" do
        canonical_url = "https://example.com/"
        expect do
          post_article(
            title: Faker::Book.title,
            body_markdown: "Yo ho ho",
            canonical_url: canonical_url,
          )
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(response.parsed_body["id"]).canonical_url).to eq(canonical_url)
      end

      it "creates an article with a canonical url in the front matter" do
        canonical_url = "https://example.com/"
        body_markdown = file_fixture("article_published_canonical_url.txt").read
        expect do
          post_article(body_markdown: body_markdown)
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(response.parsed_body["id"]).canonical_url).to eq(canonical_url)
      end

      it "creates an article with the given description" do
        description = "this is a very interesting article"
        expect do
          post_article(
            title: Faker::Book.title,
            body_markdown: "Yo ho ho",
            description: description,
          )
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(response.parsed_body["id"]).description).to eq(description)
      end

      it "creates an article with description in the front matter" do
        description = "this is a very interesting article"
        body_markdown = file_fixture("article_published_canonical_url.txt").read
        expect do
          post_article(
            body_markdown: body_markdown,
            description: description,
          )
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(response.parsed_body["id"]).description).not_to eq(description)
      end

      it "creates an article with a part of the body as a description" do
        expect do
          post_article(
            title: Faker::Book.title,
            body_markdown: "yoooo" * 100,
          )
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(response.parsed_body["id"]).description).to eq("#{'yoooo' * 20}y...")
      end

      it "does not raise an error if article params are missing" do
        headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
        expect do
          post api_articles_path, params: {}.to_json, headers: headers
        end.not_to raise_error
        expect(response.status).to eq(422)
      end

      it "fails with a nil body markdown" do
        post_article(title: Faker::Book.title, body_markdown: nil)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to be_present
      end
    end
  end

  describe "PUT /api/articles/:id" do
    let!(:api_secret)   { create(:api_secret) }
    let!(:user)         { api_secret.user }
    let(:article)       { create(:article, user: user, published: false) }
    let(:path)          { api_article_path(article.id) }
    let!(:organization) { create(:organization) }

    describe "when unauthorized" do
      it "fails with no api key" do
        put path, headers: { "content-type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "fails with the wrong api key" do
        put path, headers: { "api-key" => "foobar", "content-type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "fails with a failing secure compare" do
        allow(ActiveSupport::SecurityUtils)
          .to receive(:secure_compare).and_return(false)
        put path, headers: { "api-key" => api_secret.secret, "content-type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe "when authorized" do
      let!(:headers) { { "api-key" => api_secret.secret, "content-type" => "application/json" } }

      def put_article(**params)
        headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
        put path, params: { article: params }.to_json, headers: headers
      end

      it "returns a 403 if :write_articles scope is missing (oauth)" do
        access_token = create(:doorkeeper_access_token, resource_owner_id: user.id)
        headers = { "authorization" => "Bearer #{access_token.token}", "content-type" => "application/json" }

        title = Faker::Book.title
        body_markdown = "foobar"
        params = { title: title, body_markdown: body_markdown }
        put path, params: { article: params }.to_json, headers: headers
        expect(response).to have_http_status(:forbidden)
      end

      it "returns a 200 if :write_articles scope is provided (oauth)" do
        access_token = create(:doorkeeper_access_token, resource_owner_id: user.id, scopes: "write_articles")
        headers = { "authorization" => "Bearer #{access_token.token}", "content-type" => "application/json" }

        title = Faker::Book.title
        body_markdown = "foobar"
        params = { title: title, body_markdown: body_markdown }
        put path, params: { article: params }.to_json, headers: headers
        expect(response).to have_http_status(:ok)
      end

      it "returns a 429 status code if the rate limit is reached" do
        rate_limit_checker = instance_double(RateLimitChecker)
        retry_after_val = RateLimitChecker::ACTION_LIMITERS.dig(:article_update, :retry_after)
        rate_limit_error = RateLimitChecker::LimitReached.new(retry_after_val)
        allow(RateLimitChecker).to receive(:new).and_return(rate_limit_checker)
        allow(rate_limit_checker).to receive(:check_limit!).and_raise(rate_limit_error)

        put_article(title: Faker::Book.title, body_markdown: "foobar")

        expect(response).to have_http_status(:too_many_requests)
        expect(response.headers["retry-after"]).to eq(retry_after_val)
      end

      it "returns not found if the article does not belong to the user" do
        article = create(:article, user: create(:user))
        headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
        params = { article: { title: "foobar" } }.to_json
        put "/api/articles/#{article.id}", params: params, headers: headers
        expect(response).to have_http_status(:not_found)
      end

      it "lets a super admin update an article belonging to another user" do
        user.add_role(:super_admin)
        article = create(:article, user: create(:user))
        headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
        params = { article: { title: "foobar" } }.to_json
        put "/api/articles/#{article.id}", params: params, headers: headers
        expect(response).to have_http_status(:ok)
      end

      it "does not update title if only given a title because the article has a front matter" do
        put_article(title: Faker::Book.title)
        expect(response).to have_http_status(:ok)
        expect(article.reload.title).to eq(article.title)
        expect(response.parsed_body["title"]).to eq(article.title)
      end

      it "updates the title and the body if given a title and a body" do
        title = Faker::Book.title
        body_markdown = "foobar"
        put_article(title: title, body_markdown: body_markdown)
        expect(response).to have_http_status(:ok)
        expect(article.reload.title).to eq(title)
        expect(article.body_markdown).to eq(body_markdown)
      end

      it "updates the main_image to be empty if given an empty cover_image" do
        image = Faker::Avatar.image
        article.update(main_image: image)
        expect(article.main_image).to eq(image)

        body_markdown = file_fixture("article_published_empty_cover_image.txt").read
        put_article(
          title: Faker::Book.title,
          body_markdown: body_markdown,
        )
        expect(response).to have_http_status(:ok)
        expect(article.reload.main_image).to eq(nil)
      end

      it "updates the main_image to be empty if given a different cover_image" do
        image = Faker::Avatar.image
        article.update(main_image: image)
        expect(article.main_image).to eq(image)

        body_markdown = file_fixture("article_published_cover_image.txt").read
        put_article(
          title: Faker::Book.title,
          body_markdown: body_markdown,
        )
        expect(response).to have_http_status(:ok)
        expect(article.reload.main_image).to eq("https://dummyimage.com/100x100")
      end

      it "updates the tags" do
        expect do
          put_article(
            body_markdown: "something else here",
            tags: %w[meta discussion],
          )
          article.reload
        end.to change(article, :body_markdown) && change(article, :cached_tag_list)
      end

      it "assigns the article to a new series belonging to the user" do
        expect do
          put_article(
            title: Faker::Book.title,
            body_markdown: "Yo ho ho",
            series: "a series",
          )
        end.to change(Collection, :count).by(1)
        expect(response).to have_http_status(:ok)
        expect(article.reload.collection).not_to be(nil)
      end

      it "assigns the article to an existing series belonging to the user" do
        collection = create(:collection, user: user)
        expect do
          put_article(
            title: Faker::Book.title,
            body_markdown: "Yo ho ho",
            series: collection.slug,
          )
        end.to change(Collection, :count).by(0)
        expect(response).to have_http_status(:ok)
        expect(article.reload.collection).to eq(collection)
      end

      it "does not remove the article from a series" do
        collection = create(:collection, user: user)
        body_markdown = "Yo ho ho"
        article.update!(body_markdown: body_markdown, collection: collection)
        expect(article.collection).not_to be_nil

        put_article(
          title: Faker::Book.title,
          body_markdown: body_markdown,
        )
        expect(response).to have_http_status(:ok)
        expect(article.reload.collection).to eq(collection)
      end

      it "removes the article from a series if asked explicitly" do
        body_markdown = "Yo ho ho"

        article.update!(body_markdown: body_markdown, collection: create(:collection, user: user))
        expect(article.collection).not_to be_nil

        put_article(
          title: Faker::Book.title,
          body_markdown: body_markdown,
          series: nil, # nil will assign the article to no collections
        )
        expect(response).to have_http_status(:ok)
        expect(article.reload.collection).to be_nil
      end

      it "assigns the article to a series belonging to the article's owner, not the admin" do
        user.add_role(:super_admin)
        article = create(:article, user: create(:user))
        params = { article: { title: Faker::Book.title,
                              body_markdown: "Yo ho ho",
                              series: "a series" } }
        expect do
          put "/api/articles/#{article.id}", params: params, headers: { "api-key" => api_secret.secret }
          expect(response).to have_http_status(:ok)
        end.to change(Collection, :count).by(1)
        expect(article.reload.collection.user).to eq(article.user)
      end

      it "publishes an article" do
        expect(article.published).to be(false)
        put_article(body_markdown: "Yo ho ho", published: true)
        expect(response).to have_http_status(:ok)
        expect(article.reload.published).to be(true)
      end

      it "sends a notification when the article gets published" do
        expect(article.published).to be(false)
        allow(Notification).to receive(:send_to_followers)
        put_article(body_markdown: "Yo ho ho", published: true)
        expect(response).to have_http_status(:ok)
        expect(Notification).to have_received(:send_to_followers).with(article, "Published").once
      end

      it "only sends a notification the first time the article gets published" do
        expect(article.published).to be(false)
        allow(Notification).to receive(:send_to_followers)
        put_article(body_markdown: "Yo ho ho", published: true)
        expect(response).to have_http_status(:ok)

        article.update_columns(published: false)
        put_article(published: true)
        expect(response).to have_http_status(:ok)

        expect(Notification).to have_received(:send_to_followers).with(article, "Published").once
      end

      it "does not update the editing time when updated before publication" do
        article.update_columns(edited_at: nil)
        expect(article.published).to be(false)
        put_article(
          title: Faker::Book.title,
          body_markdown: "Yo ho ho",
        )
        expect(response).to have_http_status(:ok)
        expect(article.reload.edited_at).to be_nil
      end

      it "updates the editing time when updated after publication" do
        article.update_columns(published: true)
        put_article(
          title: Faker::Book.title,
          body_markdown: "Yo ho ho",
        )
        expect(response).to have_http_status(:ok)
        expect(article.reload.edited_at).not_to be_nil
      end

      it "does not update the editing time before publication if changed by an admin" do
        article.update_columns(edited_at: nil)
        expect(article.published).to be(false)
        user.add_role(:super_admin)
        article = create(:article, user: create(:user))
        params = { article: { title: Faker::Book.title,
                              body_markdown: "Yo ho ho" } }.to_json
        put "/api/articles/#{article.id}", params: params, headers: headers
        expect(response).to have_http_status(:ok)
        expect(article.reload.edited_at).to be_nil
      end

      it "does not update the editing time after publication if changed by an admin" do
        user.add_role(:super_admin)
        new_article = create(:article, user: create(:user))
        params = { article: { title: Faker::Book.title } }.to_json
        expect do
          put "/api/articles/#{new_article.id}", params: params, headers: headers
          article.reload
        end.not_to change(article, :edited_at)
      end

      it "updates the editing time when updated after publication if the owner is an admin" do
        user.add_role(:super_admin)
        article.update_columns(edited_at: nil, published: true)
        put_article(
          title: Faker::Book.title,
          body_markdown: "Yo ho ho",
        )
        expect(response).to have_http_status(:ok)
        expect(article.reload.edited_at).not_to be_nil
      end

      it "updates a description" do
        description = "this is a very interesting article"
        put_article(
          body_markdown: "Yo ho ho bsddsdsobo",
          description: description,
        )
        expect(response).to have_http_status(:ok)
        expect(article.reload.description).to eq(description)
      end

      it "assigns the article to the organization" do
        expect(article.organization).to be_nil
        create(:organization_membership, user: user, organization: organization)
        put_article(organization_id: organization.id)
        expect(response).to have_http_status(:ok)
        expect(article.reload.organization).to eq(organization)
      end

      it "fails if params are not a Hash" do
        # Not using the nifty put_article helper method because it expects a Hash
        headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
        string_params = "this_string_is_definitely_not_a_hash"
        put path, params: { article: string_params }.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to be_present
      end

      it "fails when article is not saved" do
        put_article(title: nil, body_markdown: nil)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to be_present
      end
    end
  end
end
