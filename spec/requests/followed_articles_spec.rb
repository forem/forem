require "rails_helper"

RSpec.describe "FollowedArticles", type: :request do
  describe "GET followed articles index" do
    before do
      @user = create(:user)
      login_as @user
    end
    it "returns empty articles array if not following anyone" do
      get "/followed_articles"
      expect(JSON.parse(response.body)["articles"]).to eq([])
    end
    it "returns articles of tag I follow" do
      article = create(:article)
      @user.follow(Tag.find_by_name(article.tag_list.first))
      get "/followed_articles"
      expect(JSON.parse(response.body)["articles"].first["title"]).to eq(article.title)
    end
  end
end
