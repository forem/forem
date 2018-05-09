require "rails_helper"

RSpec.describe "Moderations", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:comment) do
    create(:comment,
           commentable_id: article.id,
           commentable_type: "Article",
           user_id: user.id)
  end

  before do
    sign_in user
  end

  describe "GET moderations article" do
    it "returns 200 if user trusted" do
      user.add_role :trusted
      get article.path + "/mod"
      expect(response).to have_http_status(200)
    end
    it "returns 404 if user trusted not trusted" do
      expect do
        get article.path + "/mod"
      end.to raise_error(ActionController::RoutingError)
    end
  end

  describe "GET moderations comment" do
    it "returns 200 if user trusted" do
      user.add_role :trusted
      get comment.path + "/mod"
      expect(response).to have_http_status(200)
    end
    it "returns 404 if user trusted not trusted" do
      expect do
        get comment.path + "/mod"
      end.to raise_error(ActionController::RoutingError)
    end
  end
end