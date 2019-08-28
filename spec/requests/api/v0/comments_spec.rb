require "rails_helper"

RSpec.describe "Api::V0::Comments", type: :request do
  let(:article) { create(:article) }

  before do
    FactoryBot.create(:comment, commentable_type: "Article", commentable_id: article.id)
    FactoryBot.create(:comment, commentable_type: "Article", commentable_id: article.id)
  end

  describe "GET /api/comments" do
    it "returns not found if inproper article id" do
      get "/api/comments?a_id=gobbledygook"
      expect(response).to have_http_status(:not_found)
    end

    it "returns comments for article passed" do
      get "/api/comments?a_id=#{article.id}"
      expect(JSON.parse(response.body).size).to eq(2)
    end
  end
end
