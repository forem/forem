require "rails_helper"

RSpec.describe "Api::V0::Articles", type: :request do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  describe "GET /api/articles" do
    it "returns json response" do
      get "/api/articles"
      expect(response.content_type).to eq("application/json")
    end

    it "returns featured articles with no params" do
      create(:article)
      create(:article, featured: true)
      create(:article, featured: true)
      get "/api/articles"
      expect(JSON.parse(response.body).size).to eq(2)
    end

    it "returns user articles if username param is present" do
      create(:article, user_id: user1.id)
      create(:article, user_id: user1.id)
      create(:article, user_id: user2.id)
      get "/api/articles?username=#{user1.username}"
      expect(JSON.parse(response.body).size).to eq(2)
    end

    it "returns no articles if username param is unknown" do
      create(:article, user_id: user1.id)
      get "/api/articles?username=foobar"
      expect(JSON.parse(response.body).size).to eq(0)
    end

    it "returns organization articles if username param is present" do
      org = create(:organization)
      create(:article, user_id: user1.id)
      create(:article, user_id: user1.id, organization_id: org.id)
      create(:article, user_id: user1.id, organization_id: org.id)
      create(:article, user_id: user1.id)
      create(:article, user_id: user2.id)
      get "/api/articles?username=#{org.slug}"
      expect(JSON.parse(response.body).size).to eq(2)
    end

    it "returns tag articles if tag param is present" do
      article = create(:article)
      get "/api/articles?tag=#{article.tag_list.first}"
      expect(JSON.parse(response.body).size).to eq(1)
    end

    it "returns top tag articles if tag param is present" do
      article = create(:article)
      get "/api/articles?tag=#{article.tag_list.first}&top=7"
      expect(JSON.parse(response.body).size).to eq(1)
    end

    it "returns top articles if tag param is present" do
      create(:article)
      article = create(:article)
      article.update_column(:published_at, 10.days.ago)
      get "/api/articles?top=7"
      expect(JSON.parse(response.body).size).to eq(1)
    end

    it "returns not tag articles if article and tag are not approved" do
      article = create(:article, approved: false)
      tag = Tag.find_by(name: article.tag_list.first)
      tag.update(requires_approval: true)
      get "/api/articles?tag=#{tag.name}"
      expect(JSON.parse(response.body).size).to eq(0)
    end
  end

  describe "GET /api/articles/:id" do
    it "gets article based on ID" do
      article = create(:article)
      get "/api/articles/#{article.id}"
      expect(JSON.parse(response.body)["title"]).to eq(article.title)
    end

    it "fails with an unpublished article" do
      article = create(:article, published: false)
      invalid_request = lambda do
        get "/api/articles/#{article.id}"
      end
      expect(invalid_request).to raise_error(ActiveRecord::RecordNotFound)
    end

    it "fails with an unknown article ID" do
      invalid_request = lambda do
        get "/api/articles/99999"
      end
      expect(invalid_request).to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "POST /api/articles" do
    let!(:api_secret) { create(:api_secret) }
    let!(:user) { api_secret.user }
    let!(:path) { "/api/articles" }

    describe "when unauthorized" do
      it "fails with no api key" do
        post path
        expect(response).to have_http_status(:unauthorized)
      end

      it "fails with the wrong api key" do
        post path, headers: { "api-key" => "foobar" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "fails with a failing secure compare" do
        allow(ActiveSupport::SecurityUtils).
          to receive(:secure_compare).and_return(false)
        post path, headers: { "api-key" => api_secret.secret }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe "when authorized" do
      def post_article(**params)
        headers = { "api-key" => api_secret.secret }
        post path, params: { "article" => params }, headers: headers
      end

      def json_response
        JSON.parse(response.body)
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
        expect do
          post_article(
            title: Faker::Book.title + rand(100).to_s,
            publish_under_org: true,
          )
          expect(response).to have_http_status(:created)
        end.to change(Article, :count).by(1)
        expect(Article.find(json_response["id"]).organization).to eq(user.organization)
      end
    end
  end

  describe "PUT /api/articles/:id w/ current_user" do
    before do
      sign_in user1
    end

    let(:article) { create(:article, user: user1) }

    it "updates ordinary article with proper params" do
      new_title = "NEW TITLE #{rand(100)}"
      put "/api/articles/#{article.id}", params: {
        article: { title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo", version: "v2" }
      }
      expect(Article.last.title).to eq(new_title)
    end

    it "does not allow user to update a different article" do
      article.update_column(:user_id, user2.id)

      invalid_update_request = lambda do
        put "/api/articles/#{article.id}", params: {
          article: { title: "NEW TITLE #{rand(100)}",
                     body_markdown: "Yo ho ho#{rand(100)}",
                     tag_list: "yo",
                     version: "v2" }
        }
      end

      expect(invalid_update_request).to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does allow super user to update a different article" do
      new_title = "NEW TITLE #{rand(100)}"
      article.update_column(:user_id, user2.id)
      user1.add_role(:super_admin)
      put "/api/articles/#{article.id}", params: {
        article: { title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo", version: "v2" }
      }
      expect(Article.last.title).to eq(new_title)
    end

    it "allows collection to be assigned via api" do
      new_title = "NEW TITLE #{rand(100)}"
      collection = Collection.create(user_id: article.user_id, slug: "yoyoyo")
      put "/api/articles/#{article.id}", params: {
        article: { title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo", collection_id: collection.id, version: "v2" }
      }
      expect(Article.last.collection_id).to eq(collection.id)
    end

    it "does not allow collection which is not of user" do
      new_title = "NEW TITLE #{rand(100)}"
      collection = Collection.create(user_id: 3333, slug: "yoyoyo")
      put "/api/articles/#{article.id}", params: {
        article: { title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo", collection_id: collection.id, version: "v2" }
      }
      expect(Article.last.collection_id).not_to eq(collection.id)
    end
  end
end
