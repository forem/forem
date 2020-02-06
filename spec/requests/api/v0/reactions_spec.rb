require "rails_helper"

RSpec.describe "Api::V0::Reactions", type: :request do
  let(:user) { create(:user, secret: "TEST_SECRET") }
  let(:article) { create(:article) }

  describe "POST /api/reactions" do
    it "creates a new reaction for super admin users" do
      user.add_role(:super_admin)
      sign_in user

      expect do
        post api_reactions_path(
          reactable_id: article.id, reactable_type: "Article",
          category: "like", key: user.secret
        )
        expect(response).to have_http_status(:ok)
      end.to change(article.reactions, :count).by(1)
    end

    it "rejects non-authorized users" do
      sign_in user

      post api_reactions_path(
        reactable_id: article.id, reactable_type: "Article",
        category: "like", key: user.secret
      )
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
