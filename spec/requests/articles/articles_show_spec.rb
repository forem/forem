require "rails_helper"

RSpec.describe "ArticlesShow", type: :request do
  let_it_be(:user) { create(:user) }
  let_it_be(:org, reload: true) { create(:organization) }
  let_it_be(:article, reload: true) { create(:article, user: user) }

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

    xit "renders the proper published at date" do
      expect(response.body).to include CGI.escapeHTML(article.published_at&.rfc3339)
    end

    xit "renders the proper modified at date" do
      article.update(edited_at: 1.day.ago)
      expect(response.body).to include CGI.escapeHTML(article.edited_at&.rfc3339)
    end

    it "renders the proper author" do
      expect(response.body).to include CGI.escapeHTML(article.cached_user_username)
    end

    it "renders the proper organization when one is present" do
      article.update(organizations: org)
      expect(response.body).to include CGI.escapeHTML(article.organizations.name)
    end
  end
end
