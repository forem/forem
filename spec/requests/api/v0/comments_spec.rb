require "rails_helper"

RSpec.describe "Api::V0::Comments", type: :request do
  def json_response
    JSON.parse(response.body)
  end

  let_it_be(:article) { create(:article) }

  describe "GET /api/comments" do
    before do
      create(:comment, commentable: article)
    end

    it "returns not found if wrong article id" do
      get "/api/comments?a_id=gobbledygook"
      expect(response).to have_http_status(:not_found)
    end

    it "returns comments for article" do
      get "/api/comments?a_id=#{article.id}"
      expect(json_response.size).to eq(1)
    end

    it "does not include children comments in the root list" do
      # create child comment
      create(:comment, commentable: article, parent: article.comments.first)

      get "/api/comments?a_id=#{article.id}"
      expected_ids = article.comments.roots.map(&:id_code_generated)
      expect(json_response.map { |cm| cm["id_code"] }).to match_array(expected_ids)
    end

    it "includes children comments in the children list" do
      # create child comment
      parent_comment = article.comments.first
      child_comment = create(:comment, commentable: article, parent: parent_comment)

      get "/api/comments?a_id=#{article.id}"
      comment_with_children = json_response.detect { |cm| cm["id_code"] == parent_comment.id_code_generated }
      expect(comment_with_children["children"][0]["id_code"]).to eq(child_comment.id_code_generated)
    end

    it "includes granchildren comments in the children-children list" do
      # create granchild comment
      root_comment = article.comments.first
      child_comment = create(:comment, commentable: article, parent: root_comment)
      granchild_comment = create(:comment, commentable: article, parent: child_comment)

      get "/api/comments?a_id=#{article.id}"

      comment_with_descendants = json_response.detect { |cm| cm["id_code"] == root_comment.id_code_generated }
      expect(comment_with_descendants["children"][0]["children"][0]["id_code"]).to eq(granchild_comment.id_code_generated)
    end
  end

  describe "GET /api/comments/:id" do
    let_it_be(:comment) { create(:comment, commentable: article) }

    it "returns not found if wrong comment id" do
      get "/api/comments/foobar"
      expect(response).to have_http_status(:not_found)
    end

    it "returns the comment" do
      get "/api/comments/#{comment.id_code_generated}"
      expect(json_response["id_code"]).to eq(comment.id_code_generated)
    end

    it "includes children comments in the children list" do
      # create child comment
      child_comment = create(:comment, commentable: article, parent: comment)

      get "/api/comments/#{comment.id_code_generated}"
      comment_with_children = json_response
      expect(comment_with_children["children"][0]["id_code"]).to eq(child_comment.id_code_generated)
    end

    it "includes granchildren comments in the children-children list" do
      # create granchild comment
      root_comment = comment
      child_comment = create(:comment, commentable: article, parent: root_comment)
      granchild_comment = create(:comment, commentable: article, parent: child_comment)

      get "/api/comments/#{comment.id_code_generated}"

      comment_with_descendants = json_response
      expect(comment_with_descendants["children"][0]["children"][0]["id_code"]).to eq(granchild_comment.id_code_generated)
    end
  end
end
