require "rails_helper"

RSpec.describe "ArticlesShow", type: :request do
  let_it_be(:user) { create(:user) }
  let_it_be(:organization) { create(:organization) }
  let_it_be(:organization_article) { create(:article, organization_id: organization.id) }
  let_it_be(:article, reload: true) { create(:article, user: user, published: true) }

  describe "GET /:slug (articles)" do
    before do
      get article.path
    end

    it "returns a 200 status when navigating to the article's page" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the proper title" do
      expect(response.body).to include CGI.escapeHTML(article.title)
    end

    it "renders the proper published at date" do
      expect(response.body).to include CGI.escapeHTML(article.readable_publish_date)
    end

    it "renders the proper modified at date" do
      article.update(edited_at: Time.zone.now)
      get article.path
      expect(response.body).to include CGI.escapeHTML(article.edited_at.strftime("%b %d, %Y"))
    end

    it "renders the proper author" do
      expect(response.body).to include CGI.escapeHTML(article.cached_user_username)
    end

    it "renders the proper organization for an article when one is present" do
      get organization.path
      expect(response.body).to include CGI.escapeHTML(organization_article.title)
    end
  end

  context "when keywords are set up" do
    it "shows keywords" do
      SiteConfig.meta_keywords = { article: "hello, world" }
      article.update_column(:cached_tag_list, "super sheep")
      get article.path
      expect(response.body).to include('<meta name="keywords" content="super sheep, hello, world">')
    end
  end

  context "when user signed in" do
    before do
      sign_in user
      get article.path
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).not_to include "application/ld+json"
      end
    end
  end

  context "when user not signed in" do
    before do
      get article.path
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).to include "application/ld+json"
      end
    end
  end

  context "when user not signed in but internal nav triggered" do
    before do
      get article.path + "?i=i"
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).not_to include "application/ld+json"
      end
    end
  end
end
