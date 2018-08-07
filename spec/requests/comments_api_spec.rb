# http://localhost:3000/api/comments?a_id=23
require "rails_helper"

RSpec.describe "ArticlesApi", type: :request do
  let(:article) { create(:article) }

  before do
    FactoryBot.create(:comment, commentable_type: "Article", commentable_id: article.id)
    FactoryBot.create(:comment, commentable_type: "Article", commentable_id: article.id)
  end

  describe "GET /api/comments" do
    it "returns not found if inproper article id" do
      expect { get "/api/comments?a_id=gobbledygook" }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns comments for article passed" do
      get "/api/comments?a_id=#{article.id}"
      expect(JSON.parse(response.body).size).to eq(2)
    end
  end
end
