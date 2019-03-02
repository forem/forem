# controller specs are now discouraged in favor of request specs.
# This file should eventually be removed
require "rails_helper"

RSpec.describe ArticlesController, type: :controller do
  let(:user) { create(:user) }

  describe "GET #feed" do
    render_views

    it "works" do
      get :feed, format: :rss
      expect(response.status).to eq(200)
    end

    context "when :username param is not given" do
      let!(:featured_article) { create(:article, featured: true) }
      let!(:not_featured_article) { create(:article, featured: false) }

      before { get :feed, format: :rss }

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
      before { get :feed, params: { username: user.username }, format: :rss }

      it "returns only articles for that user" do
        expect(response.body).to include(user_article.title)
        expect(response.body).not_to include(organization_article.title)
      end
    end

    context "when :username param is given and belongs to an organization" do
      include_context "when user/organization articles exist"
      before { get :feed, params: { username: organization.slug }, format: :rss }

      it "returns only articles for that organization" do
        expect(response.body).not_to include(user_article.title)
        expect(response.body).to include(organization_article.title)
      end
    end

    context "when :username param is given but it belongs to nither user nor organization" do
      include_context "when user/organization articles exist"
      before { get :feed, params: { username: "unknown" }, format: :rss }

      it("renders empty body") { expect(response.body).to be_empty }
    end
  end

  describe "GET #new" do
    before { sign_in user }

    context "with authorized user" do
      it "returns a new article" do
        get :new
        expect(response).to render_template(:new)
      end
    end

    context "with authorized user with tag param" do
      it "returns a new article" do
        get :new, params: { slug: "shecoded" }
        expect(response).to render_template(:new)
      end
    end
  end
end
