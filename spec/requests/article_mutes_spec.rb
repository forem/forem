require "rails_helper"

RSpec.describe "ArticleMutes", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /article_mutes" do
    it "returns 302 upon success" do
      article = create(:article, user: user)
      patch "/article_mutes/#{article.id}",
        params: { article: { receive_notifications: false } }
      expect(response).to have_http_status(302)
    end
  end
end
