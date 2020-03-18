require "rails_helper"

RSpec.describe "Articles", type: :request do
  let(:user) { create(:user) }
  let(:tag)  { create(:tag) }

  describe "GET /feed" do
    it "returns rss+xml content" do
      create(:article, featured: true)
      get "/feed"
      expect(response.status).to eq(200)
      expect(response.content_type).to eq("application/rss+xml")
    end

    it "returns not found if no articles" do
      expect { get "/feed" }.to raise_error(ActiveRecord::RecordNotFound)
      expect { get "/feed/#{user.username}" }.to raise_error(ActiveRecord::RecordNotFound)
      expect { get "/feed/#{tag.name}" }.to raise_error(ActiveRecord::RecordNotFound)
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
      it("renders empty body") { expect { get "/feed", params: { username: "unknown" } }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    context "when format is invalid" do
      it "returns a 404 response" do
        expect { get "/feed.zip" }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "GET /feed/tag" do
    shared_context "when tagged articles exist" do
      let!(:tag_article) { create(:article, tags: tag.name) }
    end

    context "when :tag param is given and tag exists" do
      include_context "when tagged articles exist"
      before { get "/feed/tag/#{tag.name}" }

      it "returns only articles for that tag" do
        expect(response.body).to include(tag_article.title)
      end
    end

    context "when :tag param is given and tag exists and is an alias" do
      include_context "when tagged articles exist"
      before do
        alias_tag = create(:tag, alias_for: tag.name)
        get "/feed/tag/#{alias_tag.name}"
      end

      it "returns only articles for the aliased for tag" do
        expect(response.body).to include(tag_article.title)
      end
    end

    context "when :tag param is given and tag does not exist" do
      include_context "when tagged articles exist"

      it("renders empty body") { expect { get "/feed/tag/unknown" }.to raise_error(ActiveRecord::RecordNotFound) }
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

  describe "GET /:path/edit" do
    before { sign_in user }

    it "shows v1 if article has frontmatter" do
      article = create(:article, user_id: user.id)
      get "#{article.path}/edit"
      expect(response.body).to include("articleform__form--v1")
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

    it "returns unauthorized if the user is not pro" do
      article = create(:article, user: user)
      expect { get "#{article.path}/stats" }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "works successfully" do
      user.add_role(:pro)
      article = create(:article, user: user)
      get "#{article.path}/stats"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Stats for Your Article")
    end
  end

  describe "GET /delete_confirm" do
    before { sign_in user }

    context "without an article" do
      it "renders not_found" do
        article = create(:article, user: user)
        expect do
          get "#{article.path}_1/delete_confirm"
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
