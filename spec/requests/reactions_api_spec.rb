# http://localhost:3000/api/comments?a_id=23
require "rails_helper"

RSpec.describe "ArticlesApi", type: :request do
  let(:user) { create(:user, :super_admin) }
  let(:article) { create(:article) }

  before do
    user.update(secret: "TEST_SECRET")
    sign_in user
  end

  describe "POST /api/reactions" do
    it "creates a new reactions" do
      post "/api/reactions", params: {
        reactable_id: article.id, reactable_type: "Article", category: "like", key: user.secret
      }
      expect(Reaction.last.reactable_id).to eq(article.id)
    end

    it "rejects non-authorized users" do
      user.remove_role(:super_admin)
      post "/api/reactions", params: {
        reactable_id: article.id, reactable_type: "Article", category: "like", key: user.secret
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
