require "rails_helper"

RSpec.describe "Api::V0::Articles", type: :request do
  def json_response
    JSON.parse(response.body)
  end

  describe "GET /api/articles" do
    let_it_be(:article) { create(:article) }

    it "returns json response" do
      get api_articles_path
      expect(response.content_type).to eq("application/json")
    end

    it "returns featured articles if no param is given" do
      create(:article, featured: true)
      get api_articles_path
      expect(json_response.size).to eq(1)
    end

    it "returns user's articles for the given username" do
      user = create(:user)
      create_list(:article, 2, user: user)
      get api_articles_path(username: user.username)
      expect(json_response.size).to eq(2)
    end

    it "returns nothing if given user is not found" do
      get api_articles_path(username: "foobar")
      expect(json_response.size).to eq(0)
    end

    it "returns org's articles if org's slug is given" do
      user = article.user
      org = create(:organization)
      create(:article, user: user)
      create(:article, user: user, organization: org)
      get api_articles_path(username: org.slug)
      expect(json_response.size).to eq(1)
    end

    it "returns tag's articles" do
      get api_articles_path(tag: article.tag_list.first)
      expect(json_response.size).to eq(1)
    end

    it "returns top tag articles if tag and top param is present" do
      get api_articles_path(tag: article.tag_list.first, top: "7")
      expect(json_response.size).to eq(1)
    end

    it "returns top articles if top param is present" do
      old_article = create(:article)
      old_article.update_column(:published_at, 10.days.ago)
      get api_articles_path(top: "7")
      expect(json_response.size).to eq(1)
    end

    it "returns not tag articles if article and tag are not approved" do
      article.update_column(:approved, false)
      tag = Tag.find_by(name: article.tag_list.first)
      tag.update(requires_approval: true)

      get api_articles_path(tag: tag.name)
      expect(JSON.parse(response.body).size).to eq(0)
    end
  end

  describe "GET /api/articles/:id" do
    let_it_be(:article) { create(:article) }

    it "returns proper article" do
      get api_article_path(article.id)
      expect(json_response["title"]).to eq(article.title)
      expect(json_response["body_markdown"]).to eq(article.body_markdown)
      expect(json_response["tags"]).to eq(article.decorate.cached_tag_list_array)
    end

    it "returns all the relevant datetimes" do
      article.update_columns(
        edited_at: 1.minute.from_now,
        crossposted_at: 2.minutes.ago, last_comment_at: 30.seconds.ago
      )
      get api_article_path(article.id)
      expect(json_response["created_at"]).to eq(article.created_at.utc.iso8601)
      expect(json_response["edited_at"]).to eq(article.edited_at.utc.iso8601)
      expect(json_response["crossposted_at"]).to eq(article.crossposted_at.utc.iso8601)
      expect(json_response["published_at"]).to eq(article.published_at.utc.iso8601)
      expect(json_response["last_comment_at"]).to eq(article.last_comment_at.utc.iso8601)
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
  end

  describe "POST /api/articles" do
    let!(:api_secret) { create(:api_secret) }
    let!(:user) { api_secret.user }

    context "when unauthorized" do
      it "fails with no api key" do
        post api_articles_path, headers: { "content-type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "fails with the wrong api key" do
        post api_articles_path, headers: { "api-key" => "foobar", "content-type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "fails with a failing secure compare" do
        allow(ActiveSupport::SecurityUtils).
          to receive(:secure_compare).and_return(false)
        post api_articles_path, headers: { "api-key" => api_secret.secret, "content-type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe "when authorized" do
      def post_article(**params)
        headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
        post api_articles_path, params: { article: params }.to_json, headers: headers
      end

      it "fails if no params are given" do
        post_article
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "creates an article belonging to the user" do
        post_article(title: Faker::Book.title + rand(100).to_s)
        expect(response).to have_http_status(:created)
        expect(Article.find(json_response["id"]).user).to eq(user)
      end

      it "creates an unpublished article by default" do
        post_article(title: Faker::Book.title + rand(100).to_s)
        expect(response).to have_http_status(:created)
        expect(Article.find(json_response["id"]).published).to be(false)
      end

      it "returns the location of the article" do
        post_article(title: Faker::Book.title + rand(100).to_s)
        expect(response).to have_http_status(:created)
        expect(response.location).not_to be_blank
      end

      it "creates an article with only a title" do
        title = Faker::Book.title + rand(100).to_s
        expect do
          post_article(title: title)
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(json_response["id"]).title).to eq(title)
      end

      it "creates a published article" do
        title = Faker::Book.title + rand(100).to_s
        expect do
          post_article(title: title, published: true)
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(json_response["id"]).published).to be(true)
      end

      it "creates an article with a title and the markdown body" do
        body_markdown = "Yo ho ho #{rand(100)}"
        expect do
          post_article(
            title: Faker::Book.title + rand(100).to_s,
            body_markdown: body_markdown,
          )
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(json_response["id"]).body_markdown).to eq(body_markdown)
      end

      it "creates an article with a title, body and a list of tags" do
        tags = %w[meta discussion]
        expect do
          post_article(
            title: Faker::Book.title + rand(100).to_s,
            body_markdown: "Yo ho ho #{rand(100)}",
            tags: tags,
          )
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(json_response["id"]).cached_tag_list).to eq(tags.join(", "))
      end

      it "creates an unpublished article with the front matter in the body" do
        body_markdown = file_fixture("article_unpublished.txt").read
        expect do
          post_article(body_markdown: body_markdown)
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        article = Article.find(json_response["id"])
        expect(article.title).to eq("Sample Article")
        expect(article.published).to be(false)
      end

      it "creates published article with the front matter in the body" do
        body_markdown = file_fixture("article_published.txt").read
        expect do
          post_article(body_markdown: body_markdown)
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        article = Article.find(json_response["id"])
        expect(article.title).to eq("Sample Article")
        expect(article.published).to be(true)
      end

      it "creates an article within a series" do
        series = "a series"
        post_article(
          title: Faker::Book.title + rand(100).to_s,
          body_markdown: "Yo ho ho #{rand(100)}",
          series: series,
        )
        expect(response).to have_http_status(:created)
        article = Article.find(json_response["id"])
        expect(article.collection).to eq(Collection.find_by(slug: series))
        expect(article.collection.user).to eq(user)
      end

      it "creates article within a series using the front matter" do
        body_markdown = file_fixture("article_published_series.txt").read
        expect do
          post_article(body_markdown: body_markdown)
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        article = Article.find(json_response["id"])
        expect(article.collection).to eq(Collection.find_by(slug: "a series"))
        expect(article.collection.user).to eq(user)
      end

      it "creates an article on behalf of an organization" do
        organization = create(:organization)
        create(:organization_membership, user: user, organization: organization)
        expect do
          post_article(
            title: Faker::Book.title + rand(100).to_s,
            organization_id: organization.id,
          )
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(json_response["id"]).organization).to eq(organization)
      end

      it "creates an article with a main/cover image" do
        image_url = "https://dummyimage.com/100x100"
        expect do
          post_article(
            title: Faker::Book.title + rand(100).to_s,
            body_markdown: "Yo ho ho #{rand(100)}",
            main_image: image_url,
          )
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(json_response["id"]).main_image).to eq(image_url)
      end

      it "creates an article with a main/cover image in the front matter" do
        image_url = "https://dummyimage.com/100x100"
        body_markdown = file_fixture("article_published_cover_image.txt").read
        expect do
          post_article(body_markdown: body_markdown)
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(json_response["id"]).main_image).to eq(image_url)
      end

      it "creates an article with a canonical url" do
        canonical_url = "https://example.com/"
        expect do
          post_article(
            title: Faker::Book.title + rand(100).to_s,
            body_markdown: "Yo ho ho #{rand(100)}",
            canonical_url: canonical_url,
          )
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(json_response["id"]).canonical_url).to eq(canonical_url)
      end

      it "creates an article with a canonical url in the front matter" do
        canonical_url = "https://example.com/"
        body_markdown = file_fixture("article_published_canonical_url.txt").read
        expect do
          post_article(body_markdown: body_markdown)
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(json_response["id"]).canonical_url).to eq(canonical_url)
      end

      it "creates an article with the given description" do
        description = "this is a very interesting article"
        expect do
          post_article(
            title: Faker::Book.title + rand(100).to_s,
            body_markdown: "Yo ho ho #{rand(100)}",
            description: description,
          )
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(json_response["id"]).description).to eq(description)
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
        expect(Article.find(json_response["id"]).description).not_to eq(description)
      end

      it "creates an article with a part of the body as a description" do
        expect do
          post_article(
            title: Faker::Book.title + rand(100).to_s,
            body_markdown: "yooo" * 100 + rand(100).to_s,
          )
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(json_response["id"]).description).to eq("yooo" * 20 + "y...")
      end
    end
  end

  describe "PUT /api/articles/:id" do
    let!(:api_secret) { create(:api_secret) }
    let!(:user) { api_secret.user }
    let(:article) { create(:article, user: user, published: false) }
    let(:path) { "/api/articles/#{article.id}" }
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
        allow(ActiveSupport::SecurityUtils).
          to receive(:secure_compare).and_return(false)
        put path, headers: { "api-key" => api_secret.secret, "content-type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe "when authorized" do
      def put_article(**params)
        headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
        put path, params: { article: params }.to_json, headers: headers
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

      it "does not update title if only given a title" do
        put_article(title: Faker::Book.title + rand(100).to_s)
        expect(response).to have_http_status(:ok)
        expect(article.reload.title).to eq(article.title)
        expect(json_response["title"]).to eq(article.title)
      end

      it "updates the title and the body if given a title and a body" do
        title = Faker::Book.title + rand(100).to_s
        body_markdown = "foobar"
        put_article(title: title, body_markdown: body_markdown)
        expect(response).to have_http_status(:ok)
        expect(article.reload.title).to eq(title)
        expect(article.body_markdown).to eq(body_markdown)
      end

      it "updates the tags" do
        tags = %w[meta discussion]
        body_markdown = "Yo ho ho #{rand(100)}"
        put_article(
          title: Faker::Book.title + rand(100).to_s,
          body_markdown: body_markdown,
          tags: tags,
        )
        expect(response).to have_http_status(:ok)
        expect(article.reload.cached_tag_list).to eq(tags.join(", "))
        expect(article.body_markdown).to eq(body_markdown)
      end

      it "assigns the article to a new series belonging to the user" do
        expect do
          put_article(
            title: Faker::Book.title + rand(100).to_s,
            body_markdown: "Yo ho ho #{rand(100)}",
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
            title: Faker::Book.title + rand(100).to_s,
            body_markdown: "Yo ho ho #{rand(100)}",
            series: collection.slug,
          )
        end.to change(Collection, :count).by(0)
        expect(response).to have_http_status(:ok)
        expect(article.reload.collection).to eq(collection)
      end

      it "does not remove the article from a series" do
        collection = create(:collection, user: user)
        body_markdown = "Yo ho ho #{rand(100)}"
        article.update!(body_markdown: body_markdown, collection: collection)
        expect(article.collection).not_to be_nil

        put_article(
          title: Faker::Book.title + rand(100).to_s,
          body_markdown: body_markdown,
        )
        expect(response).to have_http_status(:ok)
        expect(article.reload.collection).to eq(collection)
      end

      it "removes the article from a series if asked explicitly" do
        body_markdown = "Yo ho ho #{rand(100)}"

        article.update!(body_markdown: body_markdown, collection: create(:collection, user: user))
        expect(article.collection).not_to be_nil

        put_article(
          title: Faker::Book.title + rand(100).to_s,
          body_markdown: body_markdown,
          series: nil, # nil will assign the article to no collections
        )
        expect(response).to have_http_status(:ok)
        expect(article.reload.collection).to be_nil
      end

      it "assigns the article to a series belonging to the article's owner, not the admin" do
        user.add_role(:super_admin)
        article = create(:article, user: create(:user))
        params = { article: { title: Faker::Book.title + rand(100).to_s,
                              body_markdown: "Yo ho ho #{rand(100)}",
                              series: "a series" } }
        expect do
          put "/api/articles/#{article.id}", params: params, headers: { "api-key" => api_secret.secret }
          expect(response).to have_http_status(:ok)
        end.to change(Collection, :count).by(1)
        expect(article.reload.collection.user).to eq(article.user)
      end

      it "publishes an article" do
        expect(article.published).to be(false)
        put_article(body_markdown: "Yo ho ho #{rand(100)}", published: true)
        expect(response).to have_http_status(:ok)
        expect(article.reload.published).to be(true)
      end

      it "sends a notification when the article gets published" do
        expect(article.published).to be(false)
        allow(Notification).to receive(:send_to_followers)
        put_article(body_markdown: "Yo ho ho #{rand(100)}", published: true)
        expect(response).to have_http_status(:ok)
        expect(Notification).to have_received(:send_to_followers).with(article, "Published").once
      end

      it "only sends a notification the first time the article gets published" do
        expect(article.published).to be(false)
        allow(Notification).to receive(:send_to_followers)
        put_article(body_markdown: "Yo ho ho #{rand(100)}", published: true)
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
          title: Faker::Book.title + rand(100).to_s,
          body_markdown: "Yo ho ho #{rand(100)}",
        )
        expect(response).to have_http_status(:ok)
        expect(article.reload.edited_at).to be_nil
      end

      it "updates the editing time when updated after publication" do
        article.update_columns(published: true)
        put_article(
          title: Faker::Book.title + rand(100).to_s,
          body_markdown: "Yo ho ho #{rand(100)}",
        )
        expect(response).to have_http_status(:ok)
        expect(article.reload.edited_at).not_to be_nil
      end

      it "does not update the editing time before publication if changed by an admin" do
        article.update_columns(edited_at: nil)
        expect(article.published).to be(false)
        user.add_role(:super_admin)
        article = create(:article, user: create(:user))
        headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
        params = { article: { title: Faker::Book.title + rand(100).to_s,
                              body_markdown: "Yo ho ho #{rand(100)}" } }.to_json
        put "/api/articles/#{article.id}", params: params, headers: headers
        expect(response).to have_http_status(:ok)
        expect(article.reload.edited_at).to be_nil
      end

      it "does not update the editing time after publication if changed by an admin" do
        article.update_columns(edited_at: nil, published: true)
        user.add_role(:super_admin)
        article = create(:article, user: create(:user))
        headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
        params = { article: { title: Faker::Book.title + rand(100).to_s,
                              body_markdown: "Yo ho ho #{rand(100)}" } }.to_json
        put "/api/articles/#{article.id}", params: params, headers: headers
        expect(response).to have_http_status(:ok)
        expect(article.reload.edited_at).to be_nil
      end

      it "updates the editing time when updated after publication if the owner is an admin" do
        user.add_role(:super_admin)
        article.update_columns(edited_at: nil, published: true)
        put_article(
          title: Faker::Book.title + rand(100).to_s,
          body_markdown: "Yo ho ho #{rand(100)}",
        )
        expect(response).to have_http_status(:ok)
        expect(article.reload.edited_at).not_to be_nil
      end

      it "updates a description" do
        description = "this is a very interesting article"
        put_article(description: description)
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
    end
  end
end
