require "rails_helper"

RSpec.describe "Articles", type: :request do
  let(:user) { create(:user) }
  let(:tag)  { create(:tag) }

  describe "GET /feed" do
    it "returns rss+xml content" do
      get "/feed"
      expect(response.status).to eq(200)
      expect(response.content_type).to eq("application/rss+xml")
    end

    context "when :username param is not given" do
      let!(:featured_article) { create(:article, featured: true) }
      let!(:not_featured_article) { create(:article, featured: false) }

      before { get "/feed" }

      it "returns only featured articles" do
        expect(response.body).to include(featured_article.title)
        expect(response.body).not_to include(not_featured_article.title)
      end
    end

    shared_context "when user/organization articles exist" do
      let(:organization) { create(:organization) }
      let!(:user_article) { create(:article, user_id: user.id) }
      let!(:organization_article) { create(:article, organization_id: organization.id) }
    end

    context "when :username param is given and belongs to a user" do
      include_context "when user/organization articles exist"
      before { get "/feed", params: { username: user.username } }

      it "returns only articles for that user" do
        expect(response.body).to include(user_article.title)
        expect(response.body).not_to include(organization_article.title)
      end
    end

    context "when :username param is given and belongs to an organization" do
      include_context "when user/organization articles exist"
      before { get "/feed", params: { username: organization.slug } }

      it "returns only articles for that organization" do
        expect(response.body).not_to include(user_article.title)
        expect(response.body).to include(organization_article.title)
      end
    end

    context "when :username param is given but it belongs to nither user nor organization" do
      include_context "when user/organization articles exist"
      before { get "/feed", params: { username: "unknown" } }

      it("renders empty body") { expect(response.body).to be_empty }
    end

    shared_context "when tagged articles exist" do
      let!(:tag_article) { create(:article, tags: tag.name) }
    end

    context "when :tag param is given and tag exists" do
      include_context "when tagged articles exist"
      before { get "/feed", params: { tag: tag.name } }

      it "returns only articles for that tag" do
        expect(response.body).to include(tag_article.title)
      end
    end

    context "when :tag param is given and tag exists and is an alias" do
      include_context "when tagged articles exist"
      before do
        alias_tag = create(:tag, alias_for: tag.name)
        get "/feed", params: { tag: alias_tag.name }
      end

      it "returns only articles for the aliased for tag" do
        expect(response.body).to include(tag_article.title)
      end
    end

    context "when :tag param is given and tag does not exist" do
      include_context "when tagged articles exist"
      before { get "/feed", params: { tag: "unknown" } }

      it("renders empty body") { expect(response.body).to be_empty }
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
        get "/new", params: { slug: "shecoded" }
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
