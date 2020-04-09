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
      expect(response).to have_http_status(:success)
    end

    it "renders the proper title" do
      expect(response.body).to include CGI.escapeHTML(article.title)
    end

    it "renders the proper published at date" do
      expect(response.body).to include CGI.escapeHTML(article.readable_publish_date)
    end

    it "renders the proper modified at date" do
      time_now = Time.current
      article.edited_at = time_now
      expect(response.body).to include CGI.escapeHTML(article.readable_edit_date)
    end

    it "renders the proper author" do
      expect(response.body).to include CGI.escapeHTML(article.cached_user_username)
    end

    it "renders the proper organization for an article when one is present" do
      get organization.path
      expect(response.body).to include CGI.escapeHTML(organization_article.title)
    end
  end
end
