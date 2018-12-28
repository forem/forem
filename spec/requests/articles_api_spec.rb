require "rails_helper"

RSpec.describe "ArticlesApi", type: :request do
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

    # rubocop:disable RSpec/ExampleLength
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
    # rubocop:enable RSpec/ExampleLength

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

    it "returns not tag articles if article and tag are not approved" do
      article = create(:article, approved: false)
      tag = Tag.find_by_name(article.tag_list.first)
      tag.update(requires_approval: true)
      get "/api/articles?tag=#{tag.name}"
      expect(JSON.parse(response.body).size).to eq(0)
    end
  end

  describe "GET /api/articles/:id" do
    it "data for article based on ID" do
      article = create(:article)
      get "/api/articles/#{article.id}"
      expect(JSON.parse(response.body)["title"]).to eq(article.title)
    end
  end

  describe "POST /api/articles w/ current_user" do
    before do
      sign_in user1
    end

    it "creates ordinary article with proper params" do
      new_title = "NEW TITLE #{rand(100)}"
      post "/api/articles", params: {
        article: { title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo" }
      }
      expect(Article.last.user_id).to eq(user1.id)
    end

    it "creates article with front matter params" do
      post "/api/articles", params: {
        article: {
          body_markdown: "---\ntitle: hey hey hahuu\npublished: false\n---\nYo ho ho#{rand(100)}",
          tag_list: "yo"
        }
      }
      expect(Article.last.title).to eq("hey hey hahuu")
    end

    it "creates article w/ series param" do
      new_title = "NEW TITLE #{rand(100)}"
      post "/api/articles", params: {
        article: { title: new_title,
                   body_markdown: "Yo ho ho#{rand(100)}",
                   tag_list: "yo",
                   series: "helloyo" }
      }
      expect(Article.last.collection).to eq(Collection.find_by_slug("helloyo"))
      expect(Article.last.collection.user_id).to eq(Article.last.user_id)
    end

    it "creates article within series with front matter params" do
      post "/api/articles", params: {
        article: {
          body_markdown: "---\ntitle: hey hey hahuu\npublished: false\nseries: helloyo\n---\nYo ho ho#{rand(100)}",
          tag_list: "yo"
        }
      }
      expect(Article.last.collection).to eq(Collection.find_by_slug("helloyo"))
      expect(Article.last.collection.user_id).to eq(Article.last.user_id)
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
        article: { title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo" }
      }
      expect(Article.last.title).to eq(new_title)
    end

    it "does not allow user to update a different article" do
      new_title = "NEW TITLE #{rand(100)}"
      article.update_column(:user_id, user2.id)

      expect do
        put "/api/articles/#{article.id}",
          params: { article: { title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo" } }
      end .to raise_error(ActionController::RoutingError)
    end

    it "does allow super user to update a different article" do
      new_title = "NEW TITLE #{rand(100)}"
      article.update_column(:user_id, user2.id)
      user1.add_role(:super_admin)
      put "/api/articles/#{article.id}", params: {
        article: { title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo" }
      }
      expect(Article.last.title).to eq(new_title)
    end

    it "allows collection to be assigned via api" do
      new_title = "NEW TITLE #{rand(100)}"
      collection = Collection.create(user_id: article.user_id, slug: "yoyoyo")
      put "/api/articles/#{article.id}", params: {
        article: { title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo", collection_id: collection.id }
      }
      expect(Article.last.collection_id).to eq(collection.id)
    end

    it "does not allow collection which is not of user" do
      new_title = "NEW TITLE #{rand(100)}"
      collection = Collection.create(user_id: 3333, slug: "yoyoyo")
      put "/api/articles/#{article.id}", params: {
        article: { title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo", collection_id: collection.id }
      }
      expect(Article.last.collection_id).not_to eq(collection.id)
    end
  end
end
